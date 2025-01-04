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
        def initialize(connection:, speaker: ActiveRecord::Migration.new)
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
        def on(name)
          indexes = Indexes.new(connection: connection).on(name)

          yield

          indexes.each(&method(:try_index_create))
        end

        def on_side_by_side(name, new_table_name, temporary_id)
          indexes = Indexes.new(connection: connection).on(name)
          indexes.each_with_index do |index, i|
            old_name = "predrop_index_#{temporary_id}_#{i}"
            connection.rename_index(name, index.index_name, old_name)
          end
          yield
          indexes.each do |index|
            try_index_create(index.with_other_object_name(new_table_name))
          end
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
