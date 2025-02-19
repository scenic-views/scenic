require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::IndexCreation, :db do
      it "successfully recreates applicable indexes" do
        create_materialized_view("hi", "SELECT 'hi' AS greeting")
        speaker = DummySpeaker.new

        index = Scenic::Index.new(
          object_name: "hi",
          index_name: "hi_greeting_idx",
          definition: "CREATE INDEX hi_greeting_idx ON hi (greeting)"
        )

        Postgres::IndexCreation
          .new(connection: ActiveRecord::Base.connection, speaker: speaker)
          .try_create([index])

        expect(indexes_for("hi")).not_to be_empty
        expect(speaker.messages).to include(/index 'hi_greeting_idx' .* has been created/)
      end

      it "skips indexes that are not applicable" do
        create_materialized_view("hi", "SELECT 'hi' AS greeting")
        speaker = DummySpeaker.new
        index = Scenic::Index.new(
          object_name: "hi",
          index_name: "hi_person_idx",
          definition: "CREATE INDEX hi_person_idx ON hi (person)"
        )

        Postgres::IndexCreation
          .new(connection: ActiveRecord::Base.connection, speaker: speaker)
          .try_create([index])

        expect(indexes_for("hi")).to be_empty
        expect(speaker.messages).to include(/index 'hi_person_idx' .* has been dropped/)
      end
    end

    class DummySpeaker
      attr_reader :messages

      def initialize
        @messages = []
      end

      def say(message, bool = false)
        @messages << message
      end
    end
  end
end
