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

    it "allows the views path to be set" do
      path = "db/pg/views"

      Scenic.configure do |config|
        config.views_path = path
      end

      expect(Scenic.configuration.views_path).to eq path
      expect(Scenic.views_path).to eq path
    end

    def restore_default_config
      Scenic.configuration = Configuration.new
    end
  end
end
