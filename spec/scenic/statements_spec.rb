require "spec_helper"

module Scenic
  describe Scenic::Statements do
    before do
      adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
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

      it "creates version 1 of the view if neither version nor sql_defintion are provided" do
        version = 1
        definition_stub = instance_double("Definition", to_sql: "foo")
        allow(Definition).to receive(:new)
          .with(:views, version)
          .and_return(definition_stub)

        connection.create_view :views

        expect(Scenic.database).to have_received(:create_view)
          .with(:views, definition_stub.to_sql)
      end

      it "raises an error if both version and sql_defintion are provided" do
        expect do
          connection.create_view :foo, version: 1, sql_definition: "a defintion"
        end.to raise_error ArgumentError
      end
    end

    describe "create_view :materialized" do
      it "sends the create_materialized_view message" do
        definition = instance_double("Scenic::Definition", to_sql: "definition")
        allow(Definition).to receive(:new).and_return(definition)

        connection.create_view(:views, version: 1, materialized: true)

        expect(Scenic.database).to have_received(:create_materialized_view)
          .with(:views, definition.to_sql, no_data: false)
      end
    end

    describe "create_view :materialized with :no_data" do
      it "sends the create_materialized_view message" do
        definition = instance_double("Scenic::Definition", to_sql: "definition")
        allow(Definition).to receive(:new).and_return(definition)

        connection.create_view(
          :views,
          version: 1,
          materialized: { no_data: true },
        )

        expect(Scenic.database).to have_received(:create_materialized_view)
          .with(:views, definition.to_sql, no_data: true)
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
      it "updates the view in the database" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3)
          .and_return(definition)

        connection.update_view(:name, version: 3)

        expect(Scenic.database).to have_received(:update_view)
          .with(:name, definition.to_sql)
      end

      it "updates a view from a text definition" do
        sql_definition = "a defintion"

        connection.update_view(:name, sql_definition: sql_definition)

        expect(Scenic.database).to have_received(:update_view)
          .with(:name, sql_definition)
      end

      it "updates the materialized view in the database" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3)
          .and_return(definition)

        connection.update_view(:name, version: 3, materialized: true)

        expect(Scenic.database).to have_received(:update_materialized_view)
          .with(:name, definition.to_sql, no_data: false)
      end

      it "updates the materialized view in the database with NO DATA" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3)
          .and_return(definition)

        connection.update_view(
          :name,
          version: 3,
          materialized: { no_data: true },
        )

        expect(Scenic.database).to have_received(:update_materialized_view)
          .with(:name, definition.to_sql, no_data: true)
      end

      it "raises an error if not supplied a version or sql_defintion" do
        expect { connection.update_view :views }.to raise_error(
          ArgumentError,
          /sql_definition or version must be specified/,
        )
      end

      it "raises an error if both version and sql_defintion are provided" do
        expect do
          connection.update_view(
            :views,
            version: 1,
            sql_definition: "a defintion",
          )
        end.to raise_error ArgumentError, /cannot both be set/
      end
    end

    describe "replace_view" do
      it "replaces the view in the database" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3)
          .and_return(definition)

        connection.replace_view(:name, version: 3)

        expect(Scenic.database).to have_received(:replace_view)
          .with(:name, definition.to_sql)
      end

      it "fails to replace the materialized view in the database" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3)
          .and_return(definition)

        expect do
          connection.replace_view(:name, version: 3, materialized: true)
        end.to raise_error(ArgumentError, /Cannot replace materialized views/)
      end

      it "raises an error if not supplied a version" do
        expect { connection.replace_view :views }
          .to raise_error(ArgumentError, /version is required/)
      end
    end

    def connection
      Class.new { extend Statements }
    end
  end
end
