module Scenic
  module Adapters
    class Postgres
      # Updates a view using the `side-by-side` strategy where the new view is
      # created and populated under a temporary name before the existing view is
      # dropped and the temporary view is renamed to the original name.
      class SideBySide
        def initialize(adapter:, name:, definition:, speaker: ActiveRecord::Migration.new)
          @adapter = adapter
          @name = name
          @definition = definition
          @temporary_name = TemporaryName.new(name).to_s
          @speaker = speaker
        end

        def update
          adapter.create_materialized_view(temporary_name, definition)
          say "temporary materialized view '#{temporary_name}' has been created"

          IndexMigration
            .new(connection: adapter.connection, speaker: speaker)
            .migrate(from: name, to: temporary_name)

          adapter.drop_materialized_view(name)
          say "materialized view '#{name}' has been dropped"

          rename_materialized_view(temporary_name, name)
          say "temporary materialized view '#{temporary_name}' has been renamed to '#{name}'"
        end

        private

        attr_reader :adapter, :name, :definition, :temporary_name, :speaker

        def connection
          adapter.connection
        end

        def rename_materialized_view(from, to)
          connection.execute("ALTER MATERIALIZED VIEW #{from} RENAME TO #{to}")
        end

        def say(message)
          subitem = true
          speaker.say(message, subitem)
        end
      end
    end
  end
end
