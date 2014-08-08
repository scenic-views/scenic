require "spec_helper"

module Scenic::Adapters
  describe Postgres, :db do
    describe "create_view" do
      it "successfully creates a view" do
        Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")

        expect(Postgres.views_with_definitions.keys).to include("greetings")
      end
    end

    describe "drop_view" do
      it "successfully drops a view" do
        Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")

        Postgres.drop_view("greetings")

        expect(Postgres.views_with_definitions.keys).not_to include("greetings")
      end
    end

    describe "views_with_definitions" do
      it "finds views with definitions" do
        ActiveRecord::Base.connection.execute "CREATE VIEW greetings AS SELECT text 'foo' AS foo"

        expect(Postgres.views_with_definitions.keys).to eq ["greetings"]
        expect(Postgres.views_with_definitions.values).to eq [" SELECT 'foo'::text AS foo;"]
      end
    end
  end
end
