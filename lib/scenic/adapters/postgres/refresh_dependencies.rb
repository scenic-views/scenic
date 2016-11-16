module Scenic
  module Adapters
    class Postgres
      class RefreshDependencies
        def self.call(name, adapter, connection)
          new(name, adapter, connection).call
        end

        def initialize(name, adapter, connection)
          @name = name
          @adapter = adapter
          @connection = connection
        end

        def call
          dependencies.each do |dependency|
            adapter.refresh_materialized_view(dependency)
          end
        end

        private

        attr_reader :name, :adapter, :connection

        DEPENDENCY_SQL = <<-SQL.freeze
          SELECT r_ns.nspname || '.' || cl_r.relname AS materialized_view,
          array_agg(d_ns.nspname || '.' || cl_d.relname) AS depends_on
          FROM pg_rewrite AS r
          JOIN pg_class AS cl_r ON r.ev_class=cl_r.oid
          JOIN pg_depend AS d ON r.oid=d.objid
          JOIN pg_class AS cl_d ON d.refobjid=cl_d.oid
          JOIN pg_namespace AS r_ns ON r_ns.oid = cl_r.relnamespace
          JOIN pg_namespace AS d_ns ON d_ns.oid = cl_d.relnamespace
          WHERE cl_d.relkind = 'm'
          AND cl_r.relkind = 'm'
          AND cl_d.relname != cl_r.relname
          GROUP BY cl_r.relname, r_ns.nspname
          ORDER BY cl_r.relname;
        SQL

        def dependencies
          dependency_rows = connection.select_rows(DEPENDENCY_SQL)
          dependency_hash = parse_to_hash(dependency_rows)
          sorted_arr = tsort(dependency_hash)
          idx = sorted_arr.find_index { |dep| dep.include?(name.to_s) }
          sorted_arr[0...idx]
        end

        def parse_to_hash(dependency_rows)
          dependency_rows.each_with_object({}) do |row, hash|
            formatted_dependencies = row.last.tr("{}", "").split(",")
            formatted_dependencies.each do |dependency|
              hash[dependency] = [] unless hash[dependency]
            end
            hash[row.first] = formatted_dependencies
          end
        end

        def tsort(hash)
          each_node = lambda { |&b| hash.each_key(&b) }
          each_child = lambda { |n, &b| hash[n].each(&b) }
          TSort.tsort(each_node, each_child)
        end
      end
    end
  end
end
