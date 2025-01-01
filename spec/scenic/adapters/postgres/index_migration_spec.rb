require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::IndexMigration, :db, :silence do
      it "moves indexes from the old view to the new view" do
        create_materialized_view("hi", "SELECT 'hi' AS greeting")
        create_materialized_view("hi_temp", "SELECT 'hi' AS greeting")
        add_index(:hi, :greeting, name: "hi_greeting_idx")

        Postgres::IndexMigration
          .new(connection: ActiveRecord::Base.connection)
          .migrate(from: "hi", to: "hi_temp")
        indexes_for_original = indexes_for("hi")
        indexes_for_temporary = indexes_for("hi_temp")

        expect(indexes_for_original.length).to eq 1
        expect(indexes_for_original.first.index_name).not_to eq "hi_greeting_idx"
        expect(indexes_for_temporary.length).to eq 1
        expect(indexes_for_temporary.first.index_name).to eq "hi_greeting_idx"
      end
    end
  end
end
