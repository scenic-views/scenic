require_relative "postgres/connection"
require_relative "postgres/views"
require_relative "postgres/errors"

module Scenic
  # Scenic database adapters.
  #
  # Scenic ships with a Postgres adapter only but can be extended with
  # additional adapters. The {Adapters::Postgres} adapter provides the
  # interface.
  module Adapters
    # An adapter for managing Postgres views.
    #
    # **This object is used internally by adapters and the schema dumper and is
    # not intended to be used by application code. It is documented here for
    # use by adapter gems.**
    #
    # For methods usable in migrations see {Statements}.
    #
    # @api extension
    class Postgres
      # Creates an instance of the Scenic Postgres adapter
      #
      # @param connection The database connection the adapter should use. This
      #   defaults to `ActiveRecord::Base.connection`
      def initialize(connection = ActiveRecord::Base.connection)
        @connection = Connection.new(connection)
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
      # @param name The name of the view to create
      # @param sql_definition the SQL schema for the view.
      # @return [void]
      def create_view(name, sql_definition)
        execute "CREATE VIEW #{name} AS #{sql_definition};"
      end

      # Drops the named view from the database
      #
      # @param name The name of the view to drop
      # @return [void]
      def drop_view(name)
        execute "DROP VIEW #{name};"
      end

      # Creates a materialized view in the database
      #
      # Materialized views require PostgreSQL 9.3 or newer.
      #
      # @param name The name of the materialized view to create
      # @param sql_definition The SQL schema that defines the materialized view.
      # @return [void]
      def create_materialized_view(name, sql_definition)
        raise_unless_materialized_views_supported
        execute "CREATE MATERIALIZED VIEW #{name} AS #{sql_definition};"
      end

      # Drops a materialized view in the database
      #
      # Materialized views require PostgreSQL 9.3 or newer.
      #
      # @param name The name of the materialized view to drop.
      # @return [void]
      def drop_materialized_view(name)
        raise_unless_materialized_views_supported
        execute "DROP MATERIALIZED VIEW #{name};"
      end

      # Refreshes a materialized view from its SQL schema.
      #
      # @param name The name of the materialized view to refresh.
      # @param concurrently [Boolean] Whether the refreshs hould happen
      #   concurrently or not. A concurrent refresh allows the view to be
      #   refreshed without locking the view for select but requires that the
      #   table have at least one unique index that covers all rows. Attempts to
      #   refresh concurrently without a unique index will raise a descriptive
      #   error. Concurrent refreshes require PostgreSQL 9.4 or newer.
      # @return [void]
      def refresh_materialized_view(name, concurrently: false)
        raise_unless_materialized_views_supported
        if concurrently
          raise_unless_concurrent_refresh_supported
          execute "REFRESH MATERIALIZED VIEW CONCURRENTLY #{name};"
        else
          execute "REFRESH MATERIALIZED VIEW #{name};"
        end
      end

      # Caches indexes on the provided object before executing the block and
      # then reapplying the indexes. Errors in applying the indexes are caught
      # and logged to output.
      #
      # This is used when updating a materialized view in order to maintain all
      # applicable indexes after the update.
      #
      # @param on The name of the object we are reapplying indexes on.
      # @yield Operations to perform before reapplying indexes.
      # @return [void]
      def reapplying_indexes(on: name, &_block)
        indexes = indexes_on(on)

        yield

        indexes.each { |index| say(try_index_create(index)) }
      end

      private

      attr_reader :connection
      delegate :execute, to: :connection

      def say(message)
        subitem = true
        ActiveRecord::Migration.say(message, subitem)
      end

      def indexes_on(name)
        execute(<<-SQL).map { |result| index_from_database(result) }
          SELECT
            t.relname as object_name,
            i.relname as index_name,
            pg_get_indexdef(d.indexrelid) AS definition
          FROM pg_class t
          INNER JOIN pg_index d ON t.oid = d.indrelid
          INNER JOIN pg_class i ON d.indexrelid = i.oid
          LEFT JOIN pg_namespace n ON n.oid = i.relnamespace
          WHERE i.relkind = 'i'
            AND d.indisprimary = 'f'
            AND t.relname = '#{name}'
            AND n.nspname = ANY (current_schemas(false))
          ORDER BY i.relname
        SQL
      end

      def index_from_database(result)
        Scenic::Index.new(
          object_name: result["object_name"],
          index_name: result["index_name"],
          definition: result["definition"],
        )
      end

      def try_index_create(index)
        connection.execute("SAVEPOINT #{index.index_name}")
        connection.execute(index.definition)
        connection.execute("RELEASE SAVEPOINT #{index.index_name}")
        "index '#{index.index_name}' on '#{index.object_name}' has been recreated"
      rescue ActiveRecord::StatementInvalid
        connection.execute("ROLLBACK TO SAVEPOINT #{index.index_name}")
        "index '#{index.index_name}' on '#{index.object_name}' is no longer valid and has been dropped."
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
    end
  end
end
