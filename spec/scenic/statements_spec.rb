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
          .with(:views, version, database: nil)
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
          .with(:views, version, database: nil)
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
          .with(:name, 3, database: nil)
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
          .with(:name, 3, database: nil)
          .and_return(definition)

        connection.update_view(:name, version: 3, materialized: true)

        expect(Scenic.database).to have_received(:update_materialized_view)
          .with(:name, definition.to_sql, no_data: false, side_by_side: false)
      end

      it "updates the materialized view in the database with NO DATA" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: nil)
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
          .with(:name, 3, database: nil)
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
          .with(:name, 3, database: nil)
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
          .with(:name, 3, database: nil)
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
          .with(:name, 3, database: nil)
          .and_return(definition)

        connection.replace_view(:name, version: 3)

        expect(Scenic.database).to have_received(:replace_view)
          .with(:name, definition.to_sql)
      end

      it "fails to replace the materialized view in the database" do
        definition = instance_double("Definition", to_sql: "definition")
        allow(Definition).to receive(:new)
          .with(:name, 3, database: nil)
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
            .with(:users, 1, database: nil)
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
        before do
          allow(Scenic).to receive(:database).and_call_original
        end

        after do
          Scenic.configuration = Configuration.new
        end

        it "routes view operations to the correct adapter" do
          postgres_adapter = FakeAdapter.new("Postgres")
          mysql_adapter = FakeAdapter.new("MySQL")

          Scenic.configure do |config|
            config.databases[:default] = postgres_adapter
            config.databases[:secondary] = mysql_adapter
          end

          allow(Definition).to receive(:new).and_return(
            instance_double("Definition", to_sql: "SELECT 1")
          )

          connection.create_view(:users, version: 1, database: :default)
          connection.create_view(:analytics, version: 1, database: :secondary)

          expect(postgres_adapter.call_count(:create_view)).to eq 1
          expect(mysql_adapter.call_count(:create_view)).to eq 1

          postgres_call = postgres_adapter.calls.find { |c| c[:method] == :create_view }
          mysql_call = mysql_adapter.calls.find { |c| c[:method] == :create_view }

          expect(postgres_call[:args][:name]).to eq :users
          expect(mysql_call[:args][:name]).to eq :analytics
        end

        it "routes materialized view operations to the correct adapter" do
          postgres_adapter = FakeAdapter.new("Postgres")
          mysql_adapter = FakeAdapter.new("MySQL")

          Scenic.configure do |config|
            config.databases[:default] = postgres_adapter
            config.databases[:warehouse] = mysql_adapter
          end

          allow(Definition).to receive(:new).and_return(
            instance_double("Definition", to_sql: "SELECT 1")
          )

          connection.create_view(
            :reports,
            version: 1,
            database: :default,
            materialized: true
          )
          connection.create_view(
            :aggregates,
            version: 1,
            database: :warehouse,
            materialized: true
          )

          expect(postgres_adapter.called?(:create_materialized_view)).to be true
          expect(mysql_adapter.called?(:create_materialized_view)).to be true

          postgres_call = postgres_adapter.calls.find { |c| c[:method] == :create_materialized_view }
          mysql_call = mysql_adapter.calls.find { |c| c[:method] == :create_materialized_view }

          expect(postgres_call[:args][:name]).to eq :reports
          expect(mysql_call[:args][:name]).to eq :aggregates
        end

        it "infers the database from the current connection's db_config name" do
          primary_adapter = FakeAdapter.new("Primary")
          secondary_adapter = FakeAdapter.new("Secondary")

          Scenic.configure do |config|
            config.databases[:default] = primary_adapter
            config.databases[:secondary] = secondary_adapter
          end

          allow(Definition).to receive(:new).and_return(
            instance_double("Definition", to_sql: "SELECT 1")
          )

          conn = connection(pool: fake_pool("secondary"))
          conn.create_view(:analytics, version: 1)

          expect(secondary_adapter.call_count(:create_view)).to eq 1
          expect(primary_adapter.call_count(:create_view)).to eq 0
        end

        it "uses the default adapter when the current connection is primary" do
          primary_adapter = FakeAdapter.new("Primary")
          secondary_adapter = FakeAdapter.new("Secondary")

          Scenic.configure do |config|
            config.databases[:default] = primary_adapter
            config.databases[:secondary] = secondary_adapter
          end

          allow(Definition).to receive(:new).and_return(
            instance_double("Definition", to_sql: "SELECT 1")
          )

          conn = connection(pool: fake_pool("primary"))
          conn.create_view(:users, version: 1)

          expect(primary_adapter.call_count(:create_view)).to eq 1
          expect(secondary_adapter.call_count(:create_view)).to eq 0
        end

        it "lets explicit database: override the current connection inference" do
          primary_adapter = FakeAdapter.new("Primary")
          secondary_adapter = FakeAdapter.new("Secondary")

          Scenic.configure do |config|
            config.databases[:default] = primary_adapter
            config.databases[:secondary] = secondary_adapter
          end

          allow(Definition).to receive(:new).and_return(
            instance_double("Definition", to_sql: "SELECT 1")
          )

          conn = connection(pool: fake_pool("secondary"))
          conn.create_view(:override_view, version: 1, database: :default)

          expect(primary_adapter.call_count(:create_view)).to eq 1
          expect(secondary_adapter.call_count(:create_view)).to eq 0
        end

        it "does not cross-contaminate adapter calls" do
          adapter_a = FakeAdapter.new("AdapterA")
          adapter_b = FakeAdapter.new("AdapterB")

          Scenic.configure do |config|
            config.databases[:db_a] = adapter_a
            config.databases[:db_b] = adapter_b
          end

          allow(Definition).to receive(:new).and_return(
            instance_double("Definition", to_sql: "SELECT 1")
          )

          connection.create_view(:view1, version: 1, database: :db_a)
          connection.update_view(:view2, version: 2, database: :db_b)
          connection.drop_view(:view3, database: :db_a)

          expect(adapter_a.call_count(:create_view)).to eq 1
          expect(adapter_a.call_count(:update_view)).to eq 0
          expect(adapter_a.call_count(:drop_view)).to eq 1

          expect(adapter_b.call_count(:create_view)).to eq 0
          expect(adapter_b.call_count(:update_view)).to eq 1
          expect(adapter_b.call_count(:drop_view)).to eq 0
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
