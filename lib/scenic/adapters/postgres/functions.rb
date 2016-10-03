module Scenic
  module Adapters
    class Postgres
      # Fetches defined functions from the postgres connection.
      # @api private
      class Functions
        def initialize(connection)
          @connection = connection
        end

        # All of the views that this connection has defined.
        #
        # This will include materialized views if those are supported by the
        # connection.
        #
        # @return [Array<Scenic::View>]
        def all
          functions_from_postgres.map(&method(:to_scenic_function))
        end

        private

        attr_reader :connection

        def functions_from_postgres
          connection.execute(<<-SQL)
            SELECT DISTINCT ON (p.proname) proname AS "name",
              ns.nspname AS namespace,
              t.typname,
              pg_get_function_result(p.oid) AS result_type,
              pg_get_function_arguments(p.oid) AS arguments,
              p.prosrc AS source,
              pg_get_functiondef(p.oid) AS definition
            FROM pg_proc p, pg_language l, pg_type t, pg_namespace ns
            WHERE p.prolang = l.oid
              AND p.prorettype = t.oid
              AND l.lanname = 'plpgsql'
              AND ns.nspname = ANY (current_schemas(false))
            ORDER BY proname;
          SQL
        end

        def to_scenic_function(result)
          Scenic::Function.new(result.symbolize_keys.slice(:name, :namespace, :arguments, :result_type, :source))
        end
      end
    end
  end
end
