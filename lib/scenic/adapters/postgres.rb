module Scenic
  module Adapters
    module Postgres
      def self.views_with_definitions
        Hash[execute(<<-SQL).values]
          SELECT viewname, definition
          FROM pg_views
          WHERE schemaname = ANY (current_schemas(false))
        SQL
      end

      def self.create_view(name, sql_definition)
        execute "CREATE VIEW #{name} AS #{sql_definition};"
      end

      def self.drop_view(name)
        execute "DROP VIEW #{name};"
      end

      private

      def self.execute(sql, base = ActiveRecord::Base)
        base.connection.execute sql
      end
    end
  end
end
