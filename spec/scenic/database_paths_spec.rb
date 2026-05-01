require "spec_helper"

describe Scenic::DatabasePaths do
  def hash_config(name, extra = {})
    ActiveRecord::DatabaseConfigurations::HashConfig.new(
      Rails.env,
      name,
      {adapter: "postgresql", database: "anything"}.merge(extra)
    )
  end

  describe ".config_name" do
    it "maps :default to Rails' \"primary\" convention" do
      expect(described_class.config_name(:default)).to eq "primary"
    end

    it "maps nil to \"primary\"" do
      expect(described_class.config_name(nil)).to eq "primary"
    end

    it "passes through other Scenic symbols" do
      expect(described_class.config_name(:secondary)).to eq "secondary"
      expect(described_class.config_name(:warehouse)).to eq "warehouse"
    end
  end

  describe ".views_path" do
    it "returns db/views for the default database" do
      expect(described_class.views_path(:default)).to eq Rails.root.join("db/views")
    end

    it "returns db/views for nil" do
      expect(described_class.views_path(nil)).to eq Rails.root.join("db/views")
    end

    it "returns db/<database>_views convention for non-default databases" do
      allow(ActiveRecord::Base.configurations).to receive(:configs_for)
        .with(env_name: Rails.env, name: "secondary")
        .and_return(hash_config("secondary"))

      expect(described_class.views_path(:secondary))
        .to eq Rails.root.join("db/secondary_views")
    end

    it "returns the configured views_paths when set in database.yml" do
      allow(ActiveRecord::Base.configurations).to receive(:configs_for)
        .with(env_name: Rails.env, name: "secondary")
        .and_return(hash_config("secondary", views_paths: "db/custom_views"))

      expect(described_class.views_path(:secondary))
        .to eq Rails.root.join("db/custom_views")
    end

    it "falls back to convention when configs_for returns nil" do
      allow(ActiveRecord::Base.configurations).to receive(:configs_for)
        .with(env_name: Rails.env, name: "secondary")
        .and_return(nil)

      expect(described_class.views_path(:secondary))
        .to eq Rails.root.join("db/secondary_views")
    end

    it "does not call configs_for for the default database" do
      expect(ActiveRecord::Base.configurations).not_to receive(:configs_for)

      described_class.views_path(:default)
    end
  end

  describe ".migrations_path" do
    it "returns db/migrate for the default database" do
      expect(described_class.migrations_path(:default)).to eq "db/migrate"
    end

    it "returns db/migrate for nil" do
      expect(described_class.migrations_path(nil)).to eq "db/migrate"
    end

    it "returns the configured migrations_paths when set in database.yml" do
      allow(ActiveRecord::Base.configurations).to receive(:configs_for)
        .with(env_name: Rails.env, name: "secondary")
        .and_return(hash_config("secondary", migrations_paths: "db/secondary_migrate"))

      expect(described_class.migrations_path(:secondary)).to eq "db/secondary_migrate"
    end

    it "falls back to db/<database>_migrate convention when migrations_paths is not set" do
      allow(ActiveRecord::Base.configurations).to receive(:configs_for)
        .with(env_name: Rails.env, name: "secondary")
        .and_return(hash_config("secondary"))

      expect(described_class.migrations_path(:secondary)).to eq "db/secondary_migrate"
    end

    it "does not call configs_for for the default database" do
      expect(ActiveRecord::Base.configurations).not_to receive(:configs_for)

      described_class.migrations_path(:default)
    end
  end
end
