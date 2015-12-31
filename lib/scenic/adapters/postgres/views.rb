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
          (views.to_a + materialized_views.to_a).map do |result|
            to_scenic_view(result)
          end
        end

        private

        attr_reader :connection

        def views
          connection.execute(<<-SQL)
            SELECT viewname, definition, FALSE AS materialized
            FROM pg_views
            WHERE schemaname = ANY (current_schemas(false))
            AND viewname NOT IN (SELECT extname FROM pg_extension)
          SQL
        end

        def materialized_views
          if connection.supports_materialized_views?
            connection.execute(<<-SQL)
              SELECT matviewname AS viewname, definition, TRUE AS materialized
              FROM pg_matviews
              WHERE schemaname = ANY (current_schemas(false))
            SQL
          else
            []
          end
        end

        def to_scenic_view(result)
          Scenic::View.new(
            name: result["viewname"],
            definition: result["definition"].strip,
            materialized: result["materialized"].in?(["t", true]),
          )
        end
      end
    end
  end
end
