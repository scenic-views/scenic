module Scenic
  module Adapters
    class Postgres
      # Fetches defined views from the postgres connection.
      # @api private
      class Views
        def initialize(connection)
          @connection = connection
        end

        # All of the views that this connection has defined, sorted according to
        # dependencies between the views to facilitate dumping and loading.
        #
        # This will include materialized views if those are supported by the
        # connection.
        #
        # @return [Array<Scenic::View>]
        def all
          scenic_views = views_from_postgres.map(&method(:to_scenic_view))
          sort(scenic_views)
        end

        private

        def sort(scenic_views)
          scenic_view_names = scenic_views.map(&:name)

          tsorted_views(scenic_view_names).map do |view_name|
            scenic_views.find do |sv|
              sv.name == view_name || sv.name == view_name.split(".").last
            end
          end.compact
        end

        # When dumping the views, their order must be topologically
        # sorted to take into account dependencies
        def tsorted_views(views_names)
          views_hash = TSortableHash.new

          ::Scenic.database.execute(DEPENDENT_SQL).each do |relation|
            source_v = [
              relation["source_schema"],
              relation["source_table"]
            ].compact.join(".")

            dependent = [
              relation["dependent_schema"],
              relation["dependent_view"]
            ].compact.join(".")

            views_hash[dependent] ||= []
            views_hash[source_v] ||= []
            views_hash[dependent] << source_v

            views_names.delete(relation["source_table"])
            views_names.delete(relation["dependent_view"])
          end

          # after dependencies, there might be some views left
          # that don't have any dependencies
          views_names.sort.each { |v| views_hash[v] ||= [] }
          views_hash.tsort
        end

        attr_reader :connection

        # Query for the dependencies between views
        DEPENDENT_SQL = <<~SQL.freeze
          SELECT distinct dependent_ns.nspname AS dependent_schema
          , dependent_view.relname AS dependent_view
          , source_ns.nspname AS source_schema
          , source_table.relname AS source_table
          FROM pg_depend
          JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
          JOIN pg_class as dependent_view ON pg_rewrite.ev_class = dependent_view.oid
          JOIN pg_class as source_table ON pg_depend.refobjid = source_table.oid
          JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
          JOIN pg_namespace source_ns ON source_ns.oid = source_table.relnamespace
          WHERE dependent_ns.nspname = ANY (current_schemas(false)) AND source_ns.nspname = ANY (current_schemas(false))
          AND source_table.relname != dependent_view.relname
          AND source_table.relkind IN ('m', 'v') AND dependent_view.relkind IN ('m', 'v')
          ORDER BY dependent_view.relname;
        SQL
        private_constant :DEPENDENT_SQL

        class TSortableHash < Hash
          include TSort

          alias_method :tsort_each_node, :each_key
          def tsort_each_child(node, &)
            fetch(node).each(&)
          end
        end
        private_constant :TSortableHash

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
          Scenic::View.new(
            name: namespaced_view_name(result),
            definition: result["definition"].strip,
            materialized: result["kind"] == "m"
          )
        end

        def namespaced_view_name(result)
          namespace, viewname = result.values_at("namespace", "viewname")

          if namespace != "public"
            "#{pg_identifier(namespace)}.#{pg_identifier(viewname)}"
          else
            pg_identifier(viewname)
          end
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
