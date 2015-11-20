module Scenic
  module Adapters
    class Postgres
      # Returns an array of views in the database.
      #
      # This collection of views is used by the [Scenic::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<Scenic::View>]
      def views
        execute(<<-SQL).map { |result| view_from_database(result) }
          SELECT viewname, definition, FALSE AS materialized
          FROM pg_views
          WHERE schemaname = ANY (current_schemas(false))
          AND viewname NOT IN (SELECT extname FROM pg_extension)
          UNION
          SELECT matviewname AS viewname, definition, TRUE AS materialized
          FROM pg_matviews
          WHERE schemaname = ANY (current_schemas(false))
          ORDER BY viewname
        SQL
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
      # @param name The name of the materialized view to create
      # @param sql_definition The SQL schema that defines the materialized view.
      # @return [void]
      def create_materialized_view(name, sql_definition)
        execute "CREATE MATERIALIZED VIEW #{name} AS #{sql_definition};"
      end

      # Drops a materialized view in the database
      #
      # @param name The name of the materialized view to drop.
      # @return [void]
      def drop_materialized_view(name)
        execute "DROP MATERIALIZED VIEW #{name};"
      end

      # Refreshes a materialized view from its SQL schema.
      #
      # @param name The name of the materialized view to refresh..
      # @return [void]
      def refresh_materialized_view(name)
        execute "REFRESH MATERIALIZED VIEW #{name};"
      end

      private

      def execute(sql, base = ActiveRecord::Base)
        base.connection.execute sql
      end

      def view_from_database(result)
        Scenic::View.new(
          name: result["viewname"],
          definition: result["definition"].strip,
          materialized: result["materialized"] == "t",
        )
      end
    end
  end
end
