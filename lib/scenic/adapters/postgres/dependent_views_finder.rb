module Scenic
  module Adapters
    class Postgres
      class DependentViewsFinder
        def initialize(connection, base_view_name)
          @connection = connection
          @base_view_name = qualified_name(base_view_name)
        end

        def find
          raw_dependents = connection.select_rows(dependents_sql)
          topologically_sort_dependents(raw_dependents)
        end

        private

        attr_reader :connection, :base_view_name

        def qualified_name(name)
          name.to_s.include?('.') ? name.to_s : "public.#{name}"
        end

        def dependents_sql
          unqualified_base = base_view_name.split('.').last
          schema_name = base_view_name.include?('.') ? base_view_name.split('.').first : 'public'
          
          <<-SQL
            WITH RECURSIVE dependent_views AS (
              SELECT DISTINCT
                dependent_ns.nspname || '.' || dependent_view.relname AS dependent_view,
                source_ns.nspname || '.' || source_table.relname AS source_view,
                1 AS level
              FROM pg_depend
              JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
              JOIN pg_class AS dependent_view ON pg_rewrite.ev_class = dependent_view.oid
              JOIN pg_class AS source_table ON pg_depend.refobjid = source_table.oid
              JOIN pg_namespace AS dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
              JOIN pg_namespace AS source_ns ON source_ns.oid = source_table.relnamespace
              WHERE source_table.relkind IN ('m', 'v')
                AND dependent_view.relkind IN ('m', 'v')
                AND source_table.relname != dependent_view.relname
                AND source_table.relname = '#{unqualified_base}'
                AND source_ns.nspname = '#{schema_name}'
                
              UNION ALL
              
              SELECT DISTINCT
                d2.dependent_view,
                d2.source_view,
                dv.level + 1
              FROM dependent_views dv
              JOIN (
                SELECT DISTINCT
                  dependent_ns.nspname || '.' || dependent_view.relname AS dependent_view,
                  source_ns.nspname || '.' || source_table.relname AS source_view
                FROM pg_depend
                JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
                JOIN pg_class AS dependent_view ON pg_rewrite.ev_class = dependent_view.oid
                JOIN pg_class AS source_table ON pg_depend.refobjid = source_table.oid
                JOIN pg_namespace AS dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
                JOIN pg_namespace AS source_ns ON source_ns.oid = source_table.relnamespace
                WHERE source_table.relkind IN ('m', 'v')
                  AND dependent_view.relkind IN ('m', 'v')
                  AND source_table.relname != dependent_view.relname
              ) d2 ON dv.dependent_view = d2.source_view
              WHERE dv.level < 10
            )
            SELECT dependent_view, level
            FROM dependent_views
            ORDER BY level, dependent_view;
          SQL
        end

        def topologically_sort_dependents(raw_dependents)
          return [] if raw_dependents.empty?

          dependents_by_level = raw_dependents.group_by { |row| row[1] }
          dependents_by_level.keys.sort.flat_map do |level|
            dependents_by_level[level].map { |row| row[0] }.uniq.sort
          end
        end
      end
    end
  end
end