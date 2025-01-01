module Scenic
  module Adapters
    class Postgres
      # Used during side-by-side materialized view updates to migrate indexes
      # from the original view to the new view.
      #
      # @api private
      class IndexMigration
        # Creates the index migration object.
        #
        # @param connection [Connection] The connection to execute SQL against.
        # @param speaker [#say] (ActiveRecord::Migration) The object used for
        #   logging the results of migrating indexes.
        def initialize(connection:, speaker: ActiveRecord::Migration.new)
          @connection = connection
          @speaker = speaker
        end

        # Retreives the indexes on the original view, renames them to avoid
        # collisions, retargets the indexes to the destination view, and then
        # creates the retargeted indexes.
        #
        # @param from [String] The name of the original view.
        # @param to [String] The name of the destination view.
        #
        # @return [void]
        def migrate(from:, to:)
          source_indexes = Indexes.new(connection: connection).on(from)
          retargeted_indexes = source_indexes.map { |i| retarget(i, to: to) }
          source_indexes.each(&method(:rename))

          if source_indexes.any?
            say "indexes on '#{from}' have been renamed to avoid collisions"
          end

          IndexCreation
            .new(connection: connection, speaker: speaker)
            .try_create(retargeted_indexes)
        end

        private

        attr_reader :connection, :speaker

        def retarget(index, to:)
          new_definition = index.definition.sub(
            /ON (.*)\.#{index.object_name}/,
            'ON \1.' + to + " "
          )

          Scenic::Index.new(
            object_name: to,
            index_name: index.index_name,
            definition: new_definition
          )
        end

        def rename(index)
          temporary_name = TemporaryName.new(index.index_name).to_s
          connection.rename_index(index.object_name, index.index_name, temporary_name)
        end

        def say(message)
          subitem = true
          speaker.say(message, subitem)
        end
      end
    end
  end
end
