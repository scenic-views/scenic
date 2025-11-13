require "spec_helper"

module Scenic
  describe Configuration do
    after { restore_default_config }

    it "defaults the database adapter to postgres" do
      expect(Scenic.configuration.database).to be_a Adapters::Postgres
      expect(Scenic.database).to be_a Adapters::Postgres
    end

    it "allows the database adapter to be set" do
      adapter = double("Scenic Adapter")

      Scenic.configure do |config|
        config.database = adapter
      end

      expect(Scenic.configuration.database).to eq adapter
      expect(Scenic.database).to eq adapter
    end

    it "allows multiple database adapters to be configured" do
      secondary_adapter = double("Secondary Adapter")

      Scenic.configure do |config|
        config.databases[:secondary] = secondary_adapter
      end

      expect(Scenic.configuration.databases[:secondary]).to eq secondary_adapter
    end

    it "returns the specified database adapter via Scenic.database(name)" do
      secondary_adapter = double("Secondary Adapter")

      Scenic.configure do |config|
        config.databases[:secondary] = secondary_adapter
      end

      expect(Scenic.database(:secondary)).to eq secondary_adapter
    end

    it "returns default adapter when database not found" do
      expect(Scenic.database(:nonexistent)).to eq Scenic.database(:default)
    end

    it "database= sets the default adapter" do
      adapter = double("Custom Adapter")

      Scenic.configure do |config|
        config.database = adapter
      end

      expect(Scenic.database).to eq adapter
      expect(Scenic.database(:default)).to eq adapter
    end

    describe "adapter routing with different adapter types" do
      it "routes to the correct adapter for each database" do
        primary_adapter = FakeAdapter.new("FakePostgres")
        secondary_adapter = FakeAdapter.new("FakeMySQL")

        Scenic.configure do |config|
          config.databases[:default] = primary_adapter
          config.databases[:secondary] = secondary_adapter
        end

        expect(Scenic.database(:default)).to eq primary_adapter
        expect(Scenic.database(:secondary)).to eq secondary_adapter
        expect(Scenic.database(:default).name).to eq "FakePostgres"
        expect(Scenic.database(:secondary).name).to eq "FakeMySQL"
      end

      it "maintains adapter independence" do
        adapter_a = FakeAdapter.new("AdapterA")
        adapter_b = FakeAdapter.new("AdapterB")

        Scenic.configure do |config|
          config.databases[:db_a] = adapter_a
          config.databases[:db_b] = adapter_b
        end

        Scenic.database(:db_a).create_view(:users, "SELECT 1")

        expect(adapter_a.called?(:create_view)).to be true
        expect(adapter_b.called?(:create_view)).to be false
      end
    end

    def restore_default_config
      Scenic.configuration = Configuration.new
    end
  end
end
