module Scenic
  module Adapters
    class Postgres
      # Used to resiliently create indexes on a materialized view. If the index
      # cannot be applied to the view (e.g. the columns don't exist any longer),
      # we log that information and continue rather than raising an error. It is
      # left to the user to judge whether the index is necessary and recreate
      # it.
      #
      # Used when updating a materialized view to ensure the new version has all
      # apprioriate indexes.
      #
      # @api private
      class IndexCreation
        # Creates the index creation object.
        #
        # @param connection [Connection] The connection to execute SQL against.
        # @param speaker [#say] (ActiveRecord::Migration) The object used for
        #   logging the results of creating indexes.
        def initialize(connection:, speaker: ActiveRecord::Migration.new)
          @connection = connection
          @speaker = speaker
        end

        # Creates the provided indexes. If an index cannot be created, it is
        # logged and the process continues.
        #
        # @param indexes [Array<Scenic::Index>] The indexes to create.
        #
        # @return [void]
        def try_create(indexes)
          Array(indexes).each(&method(:try_index_create))
        end

        private

        attr_reader :connection, :speaker

        def try_index_create(index)
          success = with_savepoint(index.index_name) do
            connection.execute(index.definition)
          end

          if success
            say "index '#{index.index_name}' on '#{index.object_name}' has been created"
          else
            say "index '#{index.index_name}' on '#{index.object_name}' is no longer valid and has been dropped."
          end
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
