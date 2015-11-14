require "scenic/adapters/abstract"

module Scenic
  module Adapters
    class Postgres < Abstract
      # Returns an array of views in the database.
      #
      # This collection of views is used by the [Scenic::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<Scenic::View>]
      def views
        execute(<<-SQL).map { |result| Scenic::View.new(result) }
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
    end
  end
end
