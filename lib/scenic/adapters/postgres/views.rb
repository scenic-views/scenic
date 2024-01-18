module Scenic
  module Adapters
    class Postgres
      # Fetches defined views from the postgres connection.
      # @api private
      class Views
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
          views_from_postgres.map(&method(:to_scenic_view))
        end

        private

        attr_reader :connection

        def views_from_postgres
          connection.execute(<<-SQL)
            SELECT
              c.relname as viewname,
              pg_get_viewdef(c.oid) AS definition,
              c.relkind AS kind,
              n.nspname AS namespace
            FROM pg_class c
              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE
              c.relkind IN ('m', 'v')
              AND c.relname NOT IN (SELECT extname FROM pg_extension)
              AND c.relname != 'pg_stat_statements_info'
              AND n.nspname = ANY (current_schemas(false))
            ORDER BY c.oid
          SQL
        end

        def to_scenic_view(result)
          namespace, viewname = result.values_at "namespace", "viewname"

          namespaced_viewname = if namespace != "public"
            "#{pg_identifier(namespace)}.#{pg_identifier(viewname)}"
          else
            pg_identifier(viewname)
          end

          Scenic::View.new(
            name: namespaced_viewname,
            definition: result["definition"].strip,
            materialized: result["kind"] == "m"
          )
        end

        def pg_identifier(name)
          return name if /^[a-zA-Z_][a-zA-Z0-9_]*$/.match?(name)

          pgconn.quote_ident(name)
        end

        def pgconn
          if defined?(PG::Connection)
            PG::Connection
          else
            PGconn
          end
        end
      end
    end
  end
end
