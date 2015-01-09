require "spec_helper"

module Scenic
  module Adapters
    describe Postgres, :db do
      describe "create_view" do
        it "successfully creates a view" do
          Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")

          expect(Postgres.views.map(&:name)).to include("greetings")
        end

        it "replaces a view with a new view if a view with that name already "\
          "exists" do
          Postgres.create_view("greetings", "SELECT text 'hi' AS greeting")
          Postgres.create_view("greetings", "SELECT text 'bye' AS greeting")

          expect(Postgres.views).to eq([
            View.new(
              "viewname" => "greetings",
              "definition" => "SELECT 'bye'::text AS greeting;",
            ),
          ])
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
            View.new(
              "viewname" => "greetings",
              "definition" => "SELECT 'hi'::text AS greeting;",
            ),
          ])
        end
      end
    end
  end
end
