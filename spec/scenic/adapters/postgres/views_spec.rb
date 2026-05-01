require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::Views, :db do
      it "returns scenic view objects for plain old views" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE VIEW children AS SELECT text 'Elliot' AS name
        SQL

        views = Postgres::Views.new(connection).all
        first = views.first

        expect(views.size).to eq 1
        expect(first.name).to eq "children"
        expect(first.materialized).to be false
        expect(first.definition).to eq "SELECT 'Elliot'::text AS name;"
      end

      it "queries view dependencies via the injected connection, not Scenic.database" do
        injected_connection = double("connection", execute: [])

        Postgres::Views.new(injected_connection).send(:tsorted_views, [])

        expect(injected_connection).to have_received(:execute).with(/pg_depend/)
      end

      it "returns scenic view objects for materialized views" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE MATERIALIZED VIEW children AS SELECT text 'Owen' AS name
        SQL

        views = Postgres::Views.new(connection).all
        first = views.first

        expect(views.size).to eq 1
        expect(first.name).to eq "children"
        expect(first.materialized).to be true
        expect(first.definition).to eq "SELECT 'Owen'::text AS name;"
      end
    end
  end
end
