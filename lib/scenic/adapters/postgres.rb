module Scenic
  module Adapters
    module Postgres
      def self.views
        execute(<<-SQL).map { |result| Scenic::View.new(result) }
          SELECT viewname, definition
          FROM pg_views
          WHERE schemaname = ANY (current_schemas(false))
        SQL
      end

      def self.create_view(name, sql_definition)
        execute "CREATE VIEW #{name} AS #{sql_definition};"
      end

      def self.drop_view(name, if_exists = false)
        sql = "DROP VIEW"
        sql += " IF EXISTS" if if_exists
        sql += " #{name};"
        execute sql
      end

      private

      def self.execute(sql, base = ActiveRecord::Base)
        base.connection.execute sql
      end
    end
  end
end
