module Scenic
  module Adapters
    module Postgres
      def self.views
        execute(<<-SQL).map { |result| Scenic::View.new(result) }
          SELECT viewname, definition
          FROM pg_views
          WHERE schemaname = ANY (current_schemas(false))
          AND viewname NOT IN (SELECT extname FROM pg_extension)
        SQL
      end

      def self.create_view(name, sql_definition)
        execute "CREATE VIEW #{name} AS #{sql_definition};"
      end

      def self.drop_view(name)
        execute "DROP VIEW #{name};"
      end

      def self.extensions(base = ActiveRecord::Base)
        base.connection.extensions
      end

      private

      def self.execute(sql, base = ActiveRecord::Base)
        base.connection.execute sql
      end
    end
  end
end
