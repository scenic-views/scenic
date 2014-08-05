module Scenic
  module Adapters
    module Postgres
      def self.views_with_definitions_query
        <<-SQL
          SELECT viewname, definition
          FROM pg_views
          WHERE schemaname = ANY (current_schemas(false))
        SQL
      end

      def self.create_view(name, sql_definition)
        "CREATE VIEW #{name} AS #{sql_definition};"
      end

      def self.drop_view(name)
        "DROP VIEW #{name};"
      end
    end
  end
end
