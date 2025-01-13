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

          IndexCreation
            .new(connection: connection, speaker: speaker)
            .try_create(indexes)
        end

        private

        attr_reader :connection, :speaker
      end
    end
  end
end
