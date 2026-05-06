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
          .with(:views, version, database: :default)
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
          .with(:views, version, database: :default)
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
          materialized: {no_data: true}
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
          .with(:name, 3, database: :default)
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
          .with(:name, 3, database: :default)
          .and_return(definition)

        connection.update_view(:name, version: 3, materialized: true)

        expect(Scenic.database).to have_received(:update_materialized_view)
          .with(:name, definition.to_sql, no_data: false, side_by_side: false)
      end

      it "updates the materialized view in the database with NO DATA" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: :default)
          .and_return(definition)

        connection.update_view(
          :name,
          version: 3,
          materialized: {no_data: true}
        )

        expect(Scenic.database).to have_received(:update_materialized_view)
          .with(:name, definition.to_sql, no_data: true, side_by_side: false)
      end

      it "updates the materialized view with side-by-side mode" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: :default)
          .and_return(definition)

        connection.update_view(
          :name,
          version: 3,
          materialized: {side_by_side: true}
        )

        expect(Scenic.database).to have_received(:update_materialized_view)
          .with(:name, definition.to_sql, no_data: false, side_by_side: true)
      end

      it "raises an error if not supplied a version or sql_defintion" do
        expect { connection.update_view :views }.to raise_error(
          ArgumentError,
          /sql_definition or version must be specified/
        )
      end

      it "raises an error if both version and sql_defintion are provided" do
        expect do
          connection.update_view(
            :views,
            version: 1,
            sql_definition: "a defintion"
          )
        end.to raise_error ArgumentError, /cannot both be set/
      end

      it "raises an error is no_data and side_by_side are both set" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: :default)
          .and_return(definition)

        expect do
          connection.update_view(
            :name,
            version: 3,
            materialized: {no_data: true, side_by_side: true}
          )
        end.to raise_error ArgumentError, /cannot be combined/
      end

      it "raises an error if not in a transaction" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: :default)
          .and_return(definition)

        expect do
          connection(transactions_enabled: false).update_view(
            :name,
            version: 3,
            materialized: {side_by_side: true}
          )
        end.to raise_error RuntimeError, /transaction is required/
      end
    end

    describe "replace_view" do
      it "replaces the view in the database" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: :default)
          .and_return(definition)

        connection.replace_view(:name, version: 3)

        expect(Scenic.database).to have_received(:replace_view)
          .with(:name, definition.to_sql)
      end

      it "fails to replace the materialized view in the database" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: :default)
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

    describe "multiple database support" do
      describe "create_view with database parameter" do
        it "calls the specified database adapter" do
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:secondary).and_return(secondary_adapter)

          definition = instance_double("Definition", to_sql: "SELECT 1")
          allow(Definition).to receive(:new)
            .with(:analytics, 1, database: :secondary)
            .and_return(definition)

          connection.create_view(:analytics, version: 1, database: :secondary)

          expect(secondary_adapter).to have_received(:create_view)
            .with(:analytics, definition.to_sql)
        end

        it "uses default adapter when database parameter is :default" do
          default_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:default).and_return(default_adapter)

          definition = instance_double("Definition", to_sql: "SELECT 1")
          allow(Definition).to receive(:new)
            .with(:users, 1, database: :default)
            .and_return(definition)

          connection.create_view(:users, version: 1, database: :default)

          expect(default_adapter).to have_received(:create_view)
        end
      end

      describe "drop_view with database parameter" do
        it "calls the specified database adapter" do
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:secondary).and_return(secondary_adapter)

          connection.drop_view(:analytics, database: :secondary)

          expect(secondary_adapter).to have_received(:drop_view).with(:analytics)
        end
      end

      describe "update_view with database parameter" do
        it "calls the specified database adapter" do
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:secondary).and_return(secondary_adapter)

          definition = instance_double("Definition", to_sql: "SELECT 2")
          allow(Definition).to receive(:new)
            .with(:analytics, 2, database: :secondary)
            .and_return(definition)

          connection.update_view(:analytics, version: 2, database: :secondary)

          expect(secondary_adapter).to have_received(:update_view)
            .with(:analytics, definition.to_sql)
        end
      end

      describe "replace_view with database parameter" do
        it "calls the specified database adapter" do
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:secondary).and_return(secondary_adapter)

          definition = instance_double("Definition", to_sql: "SELECT 2")
          allow(Definition).to receive(:new)
            .with(:analytics, 2, database: :secondary)
            .and_return(definition)

          connection.replace_view(:analytics, version: 2, database: :secondary)

          expect(secondary_adapter).to have_received(:replace_view)
            .with(:analytics, definition.to_sql)
        end
      end

      describe "materialized views with database parameter" do
        it "creates materialized view on specified database" do
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:secondary).and_return(secondary_adapter)

          definition = instance_double("Definition", to_sql: "SELECT 1")
          allow(Definition).to receive(:new)
            .with(:reports, 1, database: :secondary)
            .and_return(definition)

          connection.create_view(
            :reports,
            version: 1,
            database: :secondary,
            materialized: true
          )

          expect(secondary_adapter).to have_received(:create_materialized_view)
            .with(:reports, definition.to_sql, no_data: false)
        end

        it "updates materialized view on specified database" do
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:secondary).and_return(secondary_adapter)

          definition = instance_double("Definition", to_sql: "SELECT 2")
          allow(Definition).to receive(:new)
            .with(:reports, 2, database: :secondary)
            .and_return(definition)

          connection.update_view(
            :reports,
            version: 2,
            database: :secondary,
            materialized: true
          )

          expect(secondary_adapter).to have_received(:update_materialized_view)
            .with(:reports, definition.to_sql, no_data: false, side_by_side: false)
        end

        it "drops materialized view on specified database" do
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          allow(Scenic).to receive(:database).with(:secondary).and_return(secondary_adapter)

          connection.drop_view(:reports, database: :secondary, materialized: true)

          expect(secondary_adapter).to have_received(:drop_materialized_view)
        end
      end

      describe "adapter routing with different adapter types" do
        def stub_adapters(adapters)
          fake_config = Scenic::Configuration.new
          adapters.each { |name, adapter| fake_config.databases[name] = adapter }
          allow(Scenic).to receive(:configuration).and_return(fake_config)
          allow(Scenic).to receive(:database).and_call_original
          allow(Definition).to receive(:new).and_return(
            instance_double("Definition", to_sql: "SELECT 1")
          )
        end

        it "routes view operations to the correct adapter" do
          postgres_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          mysql_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          stub_adapters(default: postgres_adapter, secondary: mysql_adapter)

          connection.create_view(:users, version: 1, database: :default)
          connection.create_view(:analytics, version: 1, database: :secondary)

          expect(postgres_adapter).to have_received(:create_view).with(:users, "SELECT 1")
          expect(mysql_adapter).to have_received(:create_view).with(:analytics, "SELECT 1")
        end

        it "routes materialized view operations to the correct adapter" do
          postgres_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          mysql_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          stub_adapters(default: postgres_adapter, warehouse: mysql_adapter)

          connection.create_view(:reports, version: 1, database: :default, materialized: true)
          connection.create_view(:aggregates, version: 1, database: :warehouse, materialized: true)

          expect(postgres_adapter).to have_received(:create_materialized_view)
            .with(:reports, "SELECT 1", no_data: false)
          expect(mysql_adapter).to have_received(:create_materialized_view)
            .with(:aggregates, "SELECT 1", no_data: false)
        end

        it "infers the database from the current connection's db_config name" do
          primary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          stub_adapters(default: primary_adapter, secondary: secondary_adapter)

          connection(pool: fake_pool("secondary")).create_view(:analytics, version: 1)

          expect(secondary_adapter).to have_received(:create_view).with(:analytics, "SELECT 1")
          expect(primary_adapter).not_to have_received(:create_view)
        end

        it "uses the default adapter when the current connection is primary" do
          primary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          stub_adapters(default: primary_adapter, secondary: secondary_adapter)

          connection(pool: fake_pool("primary")).create_view(:users, version: 1)

          expect(primary_adapter).to have_received(:create_view).with(:users, "SELECT 1")
          expect(secondary_adapter).not_to have_received(:create_view)
        end

        it "lets explicit database: override the current connection inference" do
          primary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          secondary_adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
          stub_adapters(default: primary_adapter, secondary: secondary_adapter)

          connection(pool: fake_pool("secondary"))
            .create_view(:override_view, version: 1, database: :default)

          expect(primary_adapter).to have_received(:create_view).with(:override_view, "SELECT 1")
          expect(secondary_adapter).not_to have_received(:create_view)
        end

        it "does not cross-contaminate adapter calls" do
          adapter_a = instance_double("Scenic::Adapters::Postgres").as_null_object
          adapter_b = instance_double("Scenic::Adapters::Postgres").as_null_object
          stub_adapters(db_a: adapter_a, db_b: adapter_b)

          connection.create_view(:view1, version: 1, database: :db_a)
          connection.update_view(:view2, version: 2, database: :db_b)
          connection.drop_view(:view3, database: :db_a)

          expect(adapter_a).to have_received(:create_view).with(:view1, "SELECT 1")
          expect(adapter_a).to have_received(:drop_view).with(:view3)
          expect(adapter_a).not_to have_received(:update_view)

          expect(adapter_b).to have_received(:update_view).with(:view2, "SELECT 1")
          expect(adapter_b).not_to have_received(:create_view)
          expect(adapter_b).not_to have_received(:drop_view)
        end
      end
    end

    def connection(transactions_enabled: true, pool: nil)
      DummyConnection.new(transactions_enabled: transactions_enabled, pool: pool)
    end

    def fake_pool(config_name)
      Struct.new(:db_config).new(Struct.new(:name).new(config_name))
    end
  end

  class DummyConnection
    include Statements

    attr_reader :pool

    def initialize(transactions_enabled:, pool: nil)
      @transactions_enabled = transactions_enabled
      @pool = pool
    end

    def transaction_open?
      @transactions_enabled
    end
  end
end
