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

      it "returns scenic view objects with security_barrier option" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE VIEW secure_children WITH (security_barrier) AS SELECT text 'Elliot' AS name
        SQL

        views = Postgres::Views.new(connection).all
        first = views.first

        expect(views.size).to eq 1
        expect(first.name).to eq "secure_children"
        expect(first.materialized).to be false
        expect(first.definition).to eq "SELECT 'Elliot'::text AS name;"
        expect(first.options[:security_barrier]).to eq true
      end

      it "returns scenic view objects with security_invoker option" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE VIEW invoker_children WITH (security_invoker = true) AS SELECT text 'Elliot' AS name
        SQL

        views = Postgres::Views.new(connection).all
        first = views.first

        expect(views.size).to eq 1
        expect(first.name).to eq "invoker_children"
        expect(first.materialized).to be false
        expect(first.definition).to eq "SELECT 'Elliot'::text AS name;"
        expect(first.options[:security_invoker]).to eq true
      end

      it "returns scenic view objects with both security options" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-SQL
          CREATE VIEW secure_invoker_children WITH (security_barrier, security_invoker = true) AS SELECT text 'Elliot' AS name
        SQL

        views = Postgres::Views.new(connection).all
        first = views.first

        expect(views.size).to eq 1
        expect(first.name).to eq "secure_invoker_children"
        expect(first.materialized).to be false
        expect(first.definition).to eq "SELECT 'Elliot'::text AS name;"
        expect(first.options[:security_barrier]).to eq true
        expect(first.options[:security_invoker]).to eq true
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
