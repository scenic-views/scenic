require "spec_helper"

module Scenic::Adapters
  describe Postgres, :db do
    describe "create_view" do
      it "successfully creates a view" do
        Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")

        expect(Postgres.views.map(&:name)).to include("greetings")
      end
    end

    describe "drop_view" do
      it "successfully drops a view" do
        Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")

        Postgres.drop_view("greetings")

        expect(Postgres.views.map(&:name)).not_to include("greetings")
      end
    end

    describe "views" do
      it "finds views and builds Scenic::View objects" do
        ActiveRecord::Base.connection.execute "CREATE VIEW greetings AS SELECT text 'hi' AS greeting"

        expect(Postgres.views).to eq([
          Scenic::View.new(
            "viewname" => "farewells",
            "definition" => " SELECT 'bye'::text AS farewell;",
          ),
        ])
      end
    end
  end
end
