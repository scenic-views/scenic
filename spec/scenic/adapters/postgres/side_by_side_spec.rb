require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::SideBySide, :db, :silence do
      it "updates the materialized view to the new version" do
        adapter = Postgres.new
        create_materialized_view("hi", "SELECT 'hi' AS greeting")
        add_index(:hi, :greeting, name: "hi_greeting_idx")
        new_definition = "SELECT 'hola' AS greeting"

        Postgres::SideBySide
          .new(adapter: adapter, name: "hi", definition: new_definition)
          .update
        result = ar_connection.execute("SELECT * FROM hi").first["greeting"]
        indexes = indexes_for("hi")

        expect(result).to eq "hola"
        expect(indexes.length).to eq 1
        expect(indexes.first.index_name).to eq "hi_greeting_idx"
      end
    end
  end
end
