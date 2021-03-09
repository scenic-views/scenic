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
    # These methods are used interally by Scenic and are not intended for direct
    # use. Methods that alter database schema are intended to be called via
    # {Statements}, while {#refresh_materialized_view} is called via
    # {Scenic.database}.
    #
    # The methods are documented here for insight into specifics of how Scenic
    # integrates with Postgres and the responsibilities of {Adapters}.
    class Postgres
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

      # Renames a view in the database
      #
      # This is typically called in a migration via {Statements#rename_view}.
      #
      # @param from_name The previous name of the view to rename.
      # @param to_name The next name of the view to rename.
      #
      # @return [void]
      def rename_view(from_name, to_name)
        execute <<~SQL
          ALTER VIEW #{quote_table_name(from_name)}
          RENAME TO #{quote_table_name(to_name)};
        SQL
      end

      # Creates a materialized view in the database
      #
      # @param name The name of the materialized view to create
      # @param sql_definition The SQL schema that defines the materialized view.
      # @param no_data [Boolean] Default: false. Set to true to create
      #   materialized view without running the associated query. You will need
      #   to perform a non-concurrent refresh to populate with data.
      # @param copy_indexes_from [String] Default: false. Name of another view
      #   to copy indexes from. Useful when used as a first step before
      #   `replace_materialized_view`.
      #
      # This is typically called in a migration via {Statements#create_view}.
      #
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def create_materialized_view(
        name, sql_definition,
        no_data: false, copy_indexes_from: false
      )
        raise_unless_materialized_views_supported

        execute <<~SQL
          CREATE MATERIALIZED VIEW #{quote_table_name(name)} AS
          #{sql_definition.rstrip.chomp(';')}
          #{'WITH NO DATA' if no_data};
        SQL
        if copy_indexes_from
          IndexReapplication.new(connection: connection)
            .on(name, from: copy_indexes_from) {}
        end
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
      #   to perform a non-concurrent refresh to populate with data.
      #
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def update_materialized_view(name, sql_definition, no_data: false)
        raise_unless_materialized_views_supported

        IndexReapplication.new(connection: connection).on(name) do
          drop_materialized_view(name)
          create_materialized_view(name, sql_definition, no_data: no_data)
        end
      end

      # Replaces a materialized view by another.
      #
      # Most of the time this method is used as a second step after having
      # created the materialized view and refreshing it in a previous release.
      #
      # This is typically called in a migration via {Statements#replace_view}.
      #
      # @param from_name The previous name of the materialized view to rename.
      # @param to_name The next name of the materialized view to rename.
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def replace_materialized_view(from_name, to_name)
        raise_unless_materialized_views_supported

        drop_materialized_view(to_name)
        rename_materialized_view(from_name, to_name, rename_indexes: true)
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

      # Renames a materialized view in the database
      #
      # This is typically called in a migration via {Statements#rename_view}.
      #
      # @param from_name The previous name of the materialized view to rename.
      # @param to_name The next name of the materialized view to rename.
      # @param rename_indexes [Boolean] rename materialized view indexes
      #   by substituing in their name the previous view name
      #   to the next view name. Defaults to false.
      # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
      #   in use does not support materialized views.
      #
      # @return [void]
      def rename_materialized_view(from_name, to_name, rename_indexes: false)
        raise_unless_materialized_views_supported
        execute <<~SQL
          ALTER MATERIALIZED VIEW #{quote_table_name(from_name)}
          RENAME TO #{quote_table_name(to_name)};
        SQL

        if rename_indexes
          Indexes.new(connection: connection)
            .on(to_name)
            .map(&:index_name)
            .select { |name| name.match?(from_name) }
            .each do |name|
              connection.rename_index(
                to_name, name, name.to_s.sub(from_name.to_s, to_name.to_s)
              )
            end
        end
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
      #   error.
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
      #
      # @return [void]
      def refresh_materialized_view(name, concurrently: false, cascade: false)
        raise_unless_materialized_views_supported

        if cascade
          refresh_dependencies_for(name, concurrently: concurrently)
        end

        if concurrently
          raise_unless_concurrent_refresh_supported
          execute "REFRESH MATERIALIZED VIEW CONCURRENTLY #{quote_table_name(name)};"
        else
          execute "REFRESH MATERIALIZED VIEW #{quote_table_name(name)};"
        end
      end

      # Returns a normalized SQL query
      #
      # Used to compare two queries.
      #
      # @param name [String] SQL `SELECT` query.
      #
      # @return [String]
      def normalize_sql(sql_definition)
        temporary_view_name = "temp_view_for_normalization"
        view_name = quote_table_name(temporary_view_name)
        transaction do
          execute "CREATE TEMPORARY VIEW #{view_name} AS #{sql_definition};"
          view = normalize_view_sql(temporary_view_name)
          execute "DROP VIEW IF EXISTS #{view_name};"
          view
        end
      end

      # Returns a normalized SQL definition of a view
      #
      # Used to compare two queries.
      #
      # @param name [String] view name.
      #
      # @return [String]
      def normalize_view_sql(name)
        select_value("SELECT pg_get_viewdef(to_regclass(#{quote(name)}))")
          .try(:strip)
      end

      # Compare the SQL definition of the view stored in the database
      #   with the definition used to create the migrations.
      #
      # @param definition [Scenic::Definition] view definition to compare
      #   with the database.
      #
      # @return [Boolean]
      def view_with_similar_definition?(definition)
        normalize_view_sql(definition.name) == normalize_sql(definition.to_sql)
      end

      private

      attr_reader :connectable
      delegate(
        :execute, :quote, :quote_table_name, :select_value, :transaction,
        to: :connection
      )

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
          concurrently: concurrently,
        )
      end
    end
  end
end
