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

        class DependencyParser
          def initialize(raw_dependencies, view_to_refresh)
            @raw_dependencies = raw_dependencies
            @view_to_refresh = view_to_refresh
          end

          # We're given an array from the SQL query that looks kind of like this
          # [["view_name", "{'dependency_1', 'dependency_2'}"]]
          #
          # We need to parse that into a more easy to understand data type so we
          # can use the Tsort module from the Standard Library to topologically
          # sort those out so we can refresh in the correct order, so we parse
          # that raw data into a hash.
          #
          # Then, once Tsort has worked it magic, we're given a sorted 1-D array
          # ["dependency_1", "dependency_2", "view_name"]
          #
          # So we then need to slice off just the bit leading up to the view
          # that we're refreshing, so we find where in the topologically sorted
          # array our given view is, and return all the dependencies up to that
          # point.
          def to_sorted_array
            dependency_hash = parse_to_hash(raw_dependencies)
            sorted_arr = tsort(dependency_hash)
            idx = sorted_arr.find_index do |dep|
              dep.include?(view_to_refresh.to_s)
            end
            return [] if idx.nil?
            sorted_arr[0...idx]
          end

          private

          attr_reader :raw_dependencies, :view_to_refresh

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

        DEPENDENCY_SQL = <<-SQL.freeze
          SELECT rewrite_namespace.nspname || '.' || class_for_rewrite.relname AS materialized_view,
          array_agg(depend_namespace.nspname || '.' || class_for_depend.relname) AS depends_on
          FROM pg_rewrite AS rewrite
          JOIN pg_class AS class_for_rewrite ON rewrite.ev_class = class_for_rewrite.oid
          JOIN pg_depend AS depend ON rewrite.oid = depend.objid
          JOIN pg_class AS class_for_depend ON depend.refobjid = class_for_depend.oid
          JOIN pg_namespace AS rewrite_namespace ON rewrite_namespace.oid = class_for_rewrite.relnamespace
          JOIN pg_namespace AS depend_namespace ON depend_namespace.oid = class_for_depend.relnamespace
          WHERE class_for_depend.relkind = 'm'
          AND class_for_rewrite.relkind = 'm'
          AND class_for_depend.relname != class_for_rewrite.relname
          GROUP BY class_for_rewrite.relname, rewrite_namespace.nspname
          ORDER BY class_for_rewrite.relname;
        SQL

        private_constant "DependencyParser"
        private_constant "DEPENDENCY_SQL"

        def dependencies
          raw_dependency_info = connection.select_rows(DEPENDENCY_SQL)
          DependencyParser.new(raw_dependency_info, name).to_sorted_array
        end
      end
    end
  end
end
