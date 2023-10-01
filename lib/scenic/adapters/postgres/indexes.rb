module Scenic
  module Adapters
    class Postgres
      # Fetches indexes on objects from the Postgres connection.
      #
      # @api private
      class Indexes
        def initialize(connection:)
          @connection = connection
        end

        # Indexes on the provided object.
        #
        # @param name [String] The name of the object we want indexes from.
        # @return [Array<Scenic::Index>]
        def on(name)
          indexes_on(name).map(&method(:index_from_database))
        end

        private

        attr_reader :connection
        delegate :quote_table_name, to: :connection

        def indexes_on(name)
          schema, table = extract_schema_and_table(name.to_s)
          connection.execute(<<-SQL)
            SELECT
              t.relname as object_name,
              i.relname as index_name,
              pg_get_indexdef(d.indexrelid) AS definition
            FROM pg_class t
            INNER JOIN pg_index d ON t.oid = d.indrelid
            INNER JOIN pg_class i ON d.indexrelid = i.oid
            LEFT JOIN pg_namespace n ON n.oid = i.relnamespace
            WHERE i.relkind = 'i'
              AND d.indisprimary = 'f'
              AND t.relname = #{connection.quote(table)}
              AND n.nspname = #{schema ? connection.quote(schema) : 'ANY (current_schemas(false))'}
            ORDER BY i.relname
          SQL
        end

        def index_from_database(result)
          Scenic::Index.new(
            object_name: result["object_name"],
            index_name: result["index_name"],
            definition: result["definition"],
          )
        end

        def extract_schema_and_table(string)
          schema, table = string.scan(/[^".]+|"[^"]*"/)
          if table.nil?
            table = schema
            schema = nil
          end
          [schema, table]
        end
      end
    end
  end
end
