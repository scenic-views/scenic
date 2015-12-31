require "spec_helper"

module Scenic
  module Adapters
    describe Postgres, :db do
      describe "#create_view" do
        it "successfully creates a view" do
          adapter = Postgres.new

          adapter.create_view("greetings", "SELECT text 'hi' AS greeting")

          expect(adapter.views.map(&:name)).to include("greetings")
        end
      end

      describe "#create_materialized_view" do
        it "successfully creates a materialized view" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )

          view = adapter.views.first
          expect(view.name).to eq("greetings")
          expect(view.materialized).to eq true
        end
      end

      describe "#drop_view" do
        it "successfully drops a view" do
          adapter = Postgres.new

          adapter.create_view("greetings", "SELECT text 'hi' AS greeting")
          adapter.drop_view("greetings")

          expect(adapter.views.map(&:name)).not_to include("greetings")
        end
      end

      describe "#drop_materialized_view" do
        it "successfully drops a materialized view" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )
          adapter.drop_materialized_view("greetings")

          expect(adapter.views.map(&:name)).not_to include("greetings")
        end
      end

      describe "#refresh_materialized_view" do
        it "raises descriptive error if concurrent refresh is not possible" do
          adapter = Postgres.new
          adapter.create_materialized_view(:tests, "SELECT text 'hi' as text")

          expect {
            adapter.refresh_materialized_view(:tests, concurrently: true)
          }.to raise_error(/Create a unique index with no WHERE clause/)
        end
      end

      describe "#views" do
        it "returns the views defined on this connection" do
          adapter = Postgres.new

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE VIEW parents AS SELECT text 'Joe' AS name
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE VIEW children AS SELECT text 'Owen' AS name
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE MATERIALIZED VIEW people AS
            SELECT name FROM parents UNION SELECT name FROM children
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE VIEW people_with_names AS
            SELECT name FROM people
            WHERE name IS NOT NULL
          SQL

          expect(adapter.views.map(&:name)).to eq [
            "parents",
            "children",
            "people",
            "people_with_names",
          ]
        end
      end
    end
  end
end
