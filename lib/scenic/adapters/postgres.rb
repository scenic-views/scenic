require_relative "postgres/connection"
require_relative "postgres/errors"
require_relative "postgres/index_reapplication"
require_relative "postgres/indexes"
require_relative "postgres/views"
require_relative "postgres/refresh_dependencies"

module Scenic
  # Scenic database adapters.
  #
  # Scenic ships with a Postgres adapter only but can be extended with
  # additional adapters. The {Adapters::Postgres} adapter provides the
  # interface.
  module Adapters
    # An adapter for managing Postgres views.
    #
    # These methods are used internally by Scenic and are not intended for direct
    # use. Methods that alter database schema are intended to be called via
    # {Statements}, while {#refresh_materialized_view} is called via
    # {Scenic.database}.
    #
    # The methods are documented here for insight into specifics of how Scenic
    # integrates with Postgres and the responsibilities of {Adapters}.
    class Postgres
      MAX_IDENTIFIER_LENGTH = 63

      # Creates an instance of the Scenic Postgres adapter.
      #
      # This is the default adapter for Scenic. Configuring it via
      # {Scenic.configure} is not required, but the example below shows how one
      # would explicitly set it.
      #
      # @param [#connection] connectable An object that returns the connection
      #   for Scenic to use. Defaults to `ActiveRecord::Base`.
      #
      # @example
      #  Scenic.configure do |config|
      #    config.database = Scenic::Adapters::Postgres.new
      #  end
      def initialize(connectable = ActiveRecord::Base)
        @connectable = connectable
      end

      # Returns an array of views in the database.
      #
      # This collection of views is used by the [Scenic::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<Scenic::View>]
      def views
        Views.new(connection).all
      end

      # Creates a view in the database.
      #
      # This is typically called in a migration via {Statements#create_view}.
      #
      # @param name The name of the view to create
      # @param sql_definition The SQL schema for the view.
      #
      # @return [void]
      def create_view(name, sql_definition)
        execute "CREATE VIEW #{quote_table_name(name)} AS #{sql_definition};"
      end

      # Updates a view in the database.
      #
      # This results in a {#drop_view} followed by a {#create_view}. The
      # explicitness of that two step process is preferred to `CREATE OR
      # REPLACE VIEW` because the former ensures that the view you are trying to
      # update did, in fact, already exist. Additionally, `CREATE OR REPLACE
      # VIEW` is allowed only to add new columns to the end of an existing
      # view schema. Existing columns cannot be re-ordered, removed, or have
      # their types changed. Drop and create overcomes this limitation as well.
      #
      # This is typically called in a migration via {Statements#update_view}.
      #
      # @param name The name of the view to update
      # @param sql_definition The SQL schema for the updated view.
      #
      # @return [void]
      def update_view(name, sql_definition)
        drop_view(name)
        create_view(name, sql_definition)
      end

      # Replaces a view in the database using `CREATE OR REPLACE VIEW`.
      #
      # This results in a `CREATE OR REPLACE VIEW`. Most of the time the
      # explicitness of the two step process used in {#update_view} is preferred
      # to `CREATE OR REPLACE VIEW` because the former ensures that the view you
      # are trying to update did, in fact, already exist. Additionally,
      # `CREATE OR REPLACE VIEW` is allowed only to add new columns to the end
      # of an existing view schema. Existing columns cannot be re-ordered,
      # removed, or have their types changed. Drop and create overcomes this
      # limitation as well.
      #
      # However, when there is a tangled dependency tree
      # `CREATE OR REPLACE VIEW` can be preferable.
      #
      # This is typically called in a migration via
      # {Statements#replace_view}.
      #
      # @param name The name of the view to update
      # @param sql_definition The SQL schema for the updated view.
      #
      # @return [void]
      def replace_view(name, sql_definition)
        execute "CREATE OR REPLACE VIEW #{quote_table_name(name)} AS #{sql_definition};"
      end

      # Drops the named view from the database
      #
      # This is typically called in a migration via {Statements#drop_view}.
      #
      # @param name The name of the view to drop
      #
      # @return [void]
      def drop_view(name)
        execute "DROP VIEW #{quote_table_name(name)};"
      end

      # Creates a materialized view in the database
      #
      # @param name The name of the materialized view to create
      # @param sql_definition The SQL schema that defines the materialized view.
      # @param no_data [Boolean] Default: false. Set to true to create
      #   materialized view without running the associated query. You will need
      #   to perform a refresh to populate with data.
      #
      # This is typically called in a migration via {Statements#create_view}.
      #
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def create_materialized_view(name, sql_definition, no_data: false)
        raise_unless_materialized_views_supported

        execute <<-SQL
  CREATE MATERIALIZED VIEW #{quote_table_name(name)} AS
  #{sql_definition.rstrip.chomp(";")}
  #{"WITH NO DATA" if no_data};
        SQL
      end

      # Updates a materialized view in the database.
      #
      # Drops and recreates the materialized view. Attempts to maintain all
      # previously existing and still applicable indexes on the materialized
      # view after the view is recreated.
      #
      # This is typically called in a migration via {Statements#update_view}.
      #
      # @param name The name of the view to update
      # @param sql_definition The SQL schema for the updated view.
      # @param no_data [Boolean] Default: false. Set to true to create
      #   materialized view without running the associated query. You will need
      #   to perform a refresh to populate with data.
      # @param side_by_side [Boolean] Default: false. Set to true to create the
      #   new version under a different name and atomically swap them, limiting
      #   the time that a view is inaccessible at the cost of doubling disk usage
      #
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def update_materialized_view(name, sql_definition, no_data: false, side_by_side: false)
        raise_unless_materialized_views_supported

        if side_by_side
          session_id = Time.now.to_i
          new_name = generate_name name, "new_#{session_id}"
          drop_name = generate_name name, "drop_#{session_id}"
          IndexReapplication.new(connection: connection).on_side_by_side(
            name, new_name, session_id
          ) do
            create_materialized_view(new_name, sql_definition, no_data: no_data)
          end
          rename_materialized_view(name, drop_name)
          rename_materialized_view(new_name, name)
          drop_materialized_view(drop_name)
        else
          IndexReapplication.new(connection: connection).on(name) do
            drop_materialized_view(name)
            create_materialized_view(name, sql_definition, no_data: no_data)
          end
        end
      end

      # Drops a materialized view in the database
      #
      # This is typically called in a migration via {Statements#update_view}.
      #
      # @param name The name of the materialized view to drop.
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def drop_materialized_view(name)
        raise_unless_materialized_views_supported
        execute "DROP MATERIALIZED VIEW #{quote_table_name(name)};"
      end

      # Renames a materialized view from {name} to {new_name}
      #
      # @param name The existing name of the materialized view in the database.
      # @param new_name The new name to which it should be renamed
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def rename_materialized_view(name, new_name)
        raise_unless_materialized_views_supported
        execute "ALTER MATERIALIZED VIEW #{quote_table_name(name)} " \
                "RENAME TO #{quote_table_name(new_name)};"
      end

      # Refreshes a materialized view from its SQL schema.
      #
      # This is typically called from application code via {Scenic.database}.
      #
      # @param name The name of the materialized view to refresh.
      # @param concurrently [Boolean] Whether the refreshs hould happen
      #   concurrently or not. A concurrent refresh allows the view to be
      #   refreshed without locking the view for select but requires that the
      #   table have at least one unique index that covers all rows. Attempts to
      #   refresh concurrently without a unique index will raise a descriptive
      #   error. This option is ignored if the view is not populated, as it
      #   would cause an error to be raised by Postgres. Default: false.
      # @param cascade [Boolean] Whether to refresh dependent materialized
      #   views. Default: false.
      #
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      # @raise [ConcurrentRefreshesNotSupportedError] when attempting a
      #   concurrent refresh on version of Postgres that does not support
      #   concurrent materialized view refreshes.
      #
      # @example Non-concurrent refresh
      #   Scenic.database.refresh_materialized_view(:search_results)
      # @example Concurrent refresh
      #   Scenic.database.refresh_materialized_view(:posts, concurrently: true)
      # @example Cascade refresh
      #   Scenic.database.refresh_materialized_view(:posts, cascade: true)
      #
      # @return [void]
      def refresh_materialized_view(name, concurrently: false, cascade: false)
        raise_unless_materialized_views_supported

        if concurrently
          raise_unless_concurrent_refresh_supported
        end

        if cascade
          refresh_dependencies_for(name, concurrently: concurrently)
        end

        if concurrently && populated?(name)
          execute "REFRESH MATERIALIZED VIEW CONCURRENTLY #{quote_table_name(name)};"
        else
          execute "REFRESH MATERIALIZED VIEW #{quote_table_name(name)};"
        end
      end

      # True if supplied relation name is populated.
      #
      # @param name The name of the relation
      #
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [boolean]
      def populated?(name)
        raise_unless_materialized_views_supported

        schemaless_name = name.to_s.split(".").last

        sql = "SELECT relispopulated FROM pg_class WHERE relname = '#{schemaless_name}'"
        relations = execute(sql)

        if relations.count.positive?
          relations.first["relispopulated"].in?(["t", true])
        else
          false
        end
      end

      private

      attr_reader :connectable
      delegate :execute, :quote_table_name, to: :connection

      def connection
        Connection.new(connectable.connection)
      end

      def raise_unless_materialized_views_supported
        unless connection.supports_materialized_views?
          raise MaterializedViewsNotSupportedError
        end
      end

      def raise_unless_concurrent_refresh_supported
        unless connection.supports_concurrent_refreshes?
          raise ConcurrentRefreshesNotSupportedError
        end
      end

      def refresh_dependencies_for(name, concurrently: false)
        Scenic::Adapters::Postgres::RefreshDependencies.call(
          name,
          self,
          connection,
          concurrently: concurrently
        )
      end

      def generate_name(base, suffix)
        candidate = "#{base}_#{suffix}"
        if candidate.size <= MAX_IDENTIFIER_LENGTH
          candidate
        else
          digest_length = MAX_IDENTIFIER_LENGTH - suffix.size - 1
          "#{Digest::SHA256.hexdigest(base)[0...digest_length]}_#{suffix}"
        end
      end
    end
  end
end
