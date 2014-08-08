require "spec_helper"

module Scenic
  module Adapters
    describe Postgres, :db do
      describe "create_view" do
        it "successfully creates a view" do
          Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")

          expect(Postgres.views.map(&:name)).to include("greetings")
        end
      end

      describe "create_materialized_view" do
        it "successfully creates a materialized view" do
          Postgres.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )

          view = Postgres.views.first
          expect(view.name).to eq("greetings")
          expect(view.materialized).to eq true
        end
      end

      describe "drop_view" do
        it "successfully drops a view" do
          Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")

          Postgres.drop_view("greetings")

          expect(Postgres.views.map(&:name)).not_to include("greetings")
        end
      end

      describe "drop_materialized_view" do
        it "successfully drops a materialized view" do
          Postgres.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )

          Postgres.drop_materialized_view("greetings")

          expect(Postgres.views.map(&:name)).not_to include("greetings")
        end
      end

      it "finds views and builds Scenic::View objects" do
        ActiveRecord::Base.connection.execute(
          "CREATE VIEW greetings AS SELECT text 'hi' AS greeting"
        )
        ActiveRecord::Base.connection.execute(
          "CREATE MATERIALIZED VIEW farewells AS SELECT text 'bye' AS farewell"
        )

        expect(Postgres.views).to eq([
          Scenic::View.new(
            "viewname" => "farewells",
            "definition" => " SELECT 'bye'::text AS farewell;",
            "materialized" => "t",
          ),
          Scenic::View.new(
            "viewname" => "greetings",
            "definition" => " SELECT 'hi'::text AS greeting;",
            "materialized" => "f",
          ),
        ])
      end
    end
  end
end
