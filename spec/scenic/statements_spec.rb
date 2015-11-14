require "spec_helper"

module Scenic
  describe Scenic::Statements do
    before do
      adapter = instance_double("Scenic::Adapaters::Postgres").as_null_object
      allow(Scenic).to receive(:database).and_return(adapter)
    end

    describe "create_view" do
      it "creates a view from a file" do
        version = 15
        definition_stub = instance_double("Definition", to_sql: "foo")
        allow(Definition).to receive(:new)
          .with(:views, version)
          .and_return(definition_stub)

        connection.create_view :views, version: version

        expect(Scenic.database).to have_received(:create_view)
          .with(:views, definition_stub.to_sql)
      end

      it "creates a view from a text definition" do
        sql_definition = "a defintion"

        connection.create_view(:views, sql_definition: sql_definition)

        expect(Scenic.database).to have_received(:create_view)
          .with(:views, sql_definition)
      end

      it "raises an error if neither version nor sql_defintion are provided" do
        expect do
          connection.create_view :foo, version: nil, sql_definition: nil
        end.to raise_error ArgumentError
      end
    end

    describe "create_view :materialized" do
      it "sends the create_materialized_view message" do
        allow(Definition).to receive(:new)
          .and_return(instance_double("Scenic::Definition").as_null_object)

        connection.create_view(:views, version: 1, materialized: true)

        expect(Scenic.database).to have_received(:create_materialized_view)
      end
    end

    describe "drop_view" do
      it "removes a view from the database" do
        connection.drop_view :name

        expect(Scenic.database).to have_received(:drop_view).with(:name)
      end
    end

    describe "drop_view :materialized" do
      it "removes a materialized view from the database" do
        connection.drop_view :name, materialized: true

        expect(Scenic.database).to have_received(:drop_materialized_view)
      end
    end

    describe "update_view" do
      it "drops the existing version and creates the new" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3)
          .and_return(definition)

        connection.update_view(:name, version: 3)

        expect(Scenic.database).to have_received(:drop_view).with(:name)
        expect(Scenic.database).to have_received(:create_view)
          .with(:name, definition.to_sql)
      end

      it "raises an error if not supplied a version" do
        expect { connection.update_view :views }
          .to raise_error(ArgumentError, /version is required/)
      end
    end

    describe "update_view :materialized" do
      it "raises an error because this is not supported" do
        definition = instance_double("Definition").as_null_object
        allow(Definition).to receive(:new).and_return(definition)

        expect { connection.update_view(:name, version: 3, materialized: true) }.
          to raise_error(/not supported/)
        expect(Scenic.database).not_to have_received(:drop_materialized_view)
        expect(Scenic.database).not_to have_received(:create_materialized_view)
      end
    end

    def connection
      Class.new { extend Statements }
    end
  end
end
