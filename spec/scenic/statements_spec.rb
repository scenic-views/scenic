require "spec_helper"

module Scenic
  describe Scenic::Statements do
    before do
      allow(Scenic).to receive(:database)
        .and_return(class_double("Scenic::Adapters::Postgres").as_null_object)
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

    describe "drop_view" do
      it "removes a view from the database" do
        connection.drop_view :name

        expect(Scenic.database).to have_received(:drop_view).with(:name, false)
      end
    end

    describe "update_view" do
      it "drops the existing version and creates the new" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3)
          .and_return(definition)

        connection.update_view(:name, version: 3)

        expect(Scenic.database).to have_received(:drop_view).with(:name, false)
        expect(Scenic.database).to have_received(:create_view)
          .with(:name, definition.to_sql)
      end

      it "raises an error if not supplied a version" do
        expect { connection.update_view :views }
          .to raise_error(ArgumentError, /version is required/)
      end
    end

    def connection
      Class.new { extend Statements }
    end
  end
end
