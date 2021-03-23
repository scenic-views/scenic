module Scenic
  module Adapters
    class Postgres
      # Updating a materialized view causes the view to be dropped and
      # recreated. This causes any associated indexes to be dropped as well.
      # This object can be used to capture the existing indexes before the drop
      # and then reapply appropriate indexes following the create.
      #
      # @api private
      class IndexReapplication
        # Creates the index reapplication object.
        #
        # @param connection [Connection] The connection to execute SQL against.
        # @param speaker [#say] (ActiveRecord::Migration) The object used for
        #   logging the results of reapplying indexes.
        def initialize(connection:, speaker: ActiveRecord::Migration)
          @connection = connection
          @speaker = speaker
        end

        # Caches indexes on the provided object before executing the block and
        # then reapplying the indexes. Each recreated or skipped index is
        # announced to STDOUT by default. This can be overridden in the
        # constructor.
        #
        # @param name The name of the object we are reapplying indexes on.
        # @yield Operations to perform before reapplying indexes.
        #
        # @return [void]
        def on(name, from: name)
          indexes = Indexes.new(connection: connection).on(from)

          yield

          indexes
            .map(&method(:change_index_object_name).curry[from, name])
            .each(&method(:try_index_create))
        end

        private

        attr_reader :connection, :speaker

        def try_index_create(index)
          success = with_savepoint(index.index_name) do
            connection.execute(index.definition)
          end

          if success
            say "index '#{index.index_name}' on '#{index.object_name}' has been recreated"
          else
            say "index '#{index.index_name}' on '#{index.object_name}' is no longer valid and has been dropped."
          end
        end

        def change_index_object_name(from, to, index)
          return index if from == to
          index_name = index.index_name.to_s.sub(from.to_s, to.to_s)

          Scenic::Index.new(
            object_name: to,
            index_name: index_name,
            definition: index.definition.sub(
              /#{index.index_name} ON (\w+\.)?#{from}/,
              "#{index_name} ON \\1#{to}",
            ),
          )
        end

        def with_savepoint(name)
          connection.execute("SAVEPOINT #{name}")
          yield
          connection.execute("RELEASE SAVEPOINT #{name}")
          true
        rescue
          connection.execute("ROLLBACK TO SAVEPOINT #{name}")
          false
        end

        def say(message)
          subitem = true
          speaker.say(message, subitem)
        end
      end
    end
  end
end
