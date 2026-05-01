require "spec_helper"
require "generators/scenic/view/view_generator"

describe Scenic::Generators::ViewGenerator, :generator do
  it "creates view definition and migration files" do
    migration = file("db/migrate/create_searches.rb")
    view_definition = file("db/views/searches_v01.sql")

    run_generator ["search"]

    expect(migration).to be_a_migration
    expect(view_definition).to exist
  end

  it "updates an existing view" do
    with_view_definition("searches", 1, "hello") do
      migration = file("db/migrate/update_searches_to_version_2.rb")
      view_definition = file("db/views/searches_v02.sql")
      allow(Dir).to receive(:entries).and_return(["searches_v01.sql"])

      run_generator ["search"]

      expect(migration).to be_a_migration
      expect(view_definition).to exist
    end
  end

  it "adds 'materialized: true' to the migration if view is materialized" do
    with_view_definition("aired_episodes", 1, "hello") do
      allow(Dir).to receive(:entries).and_return(["aired_episodes_v01.sql"])

      run_generator ["aired_episode", "--materialized"]
      migration = migration_file(
        "db/migrate/update_aired_episodes_to_version_2.rb"
      )
      expect(migration).to contain "materialized: true"
    end
  end

  it "sets the no_data option when updating a materialized view" do
    with_view_definition("aired_episodes", 1, "hello") do
      allow(Dir).to receive(:entries).and_return(["aired_episodes_v01.sql"])

      run_generator ["aired_episode", "--materialized", "--no-data"]
      migration = migration_file(
        "db/migrate/update_aired_episodes_to_version_2.rb"
      )
      expect(migration).to contain "materialized: { no_data: true }"
      expect(migration).not_to contain "side_by_side"
    end
  end

  it "sets the side-by-side option when updating a materialized view" do
    with_view_definition("aired_episodes", 1, "hello") do
      allow(Dir).to receive(:entries).and_return(["aired_episodes_v01.sql"])

      run_generator ["aired_episode", "--materialized", "--side-by-side"]
      migration = migration_file(
        "db/migrate/update_aired_episodes_to_version_2.rb"
      )
      expect(migration).to contain "materialized: { side_by_side: true }"
      expect(migration).not_to contain "no_data"
    end
  end

  it "uses 'replace_view' instead of 'update_view' if replace flag is set" do
    with_view_definition("aired_episodes", 1, "hello") do
      allow(Dir).to receive(:entries).and_return(["aired_episodes_v01.sql"])

      run_generator ["aired_episode", "--replace"]
      migration = migration_file(
        "db/migrate/update_aired_episodes_to_version_2.rb"
      )
      expect(migration).to contain "replace_view"
    end
  end

  context "when --database is set" do
    let(:secondary_config_hash) do
      {
        adapter: "postgresql",
        database: "dummy_test2"
      }
    end

    def hash_config(extra = {})
      ActiveRecord::DatabaseConfigurations::HashConfig.new(
        Rails.env,
        "secondary",
        secondary_config_hash.merge(extra)
      )
    end

    def stub_secondary_config(db_config)
      allow(ActiveRecord::Base.configurations).to receive(:configs_for)
        .with(env_name: Rails.env, name: "secondary")
        .and_return(db_config)
    end

    it "creates the configured views_paths directory" do
      stub_secondary_config(hash_config(views_paths: "db/custom_views"))

      run_generator ["search", "--database=secondary"]

      expect(file("db/custom_views")).to exist
    end

    it "creates db/<database>_views when views_paths is not configured" do
      stub_secondary_config(hash_config)

      run_generator ["search", "--database=secondary"]

      expect(file("db/secondary_views")).to exist
    end

    it "creates db/<database>_views when configs_for returns nil" do
      stub_secondary_config(nil)

      run_generator ["search", "--database=secondary"]

      expect(file("db/secondary_views")).to exist
    end
  end

  context "for views created in a schema other than 'public'" do
    it "creates a view definition" do
      view_definition = file("db/views/non_public_searches_v01.sql")

      run_generator ["non_public.search"]

      expect(view_definition).to exist
    end

    it "creates a migration file" do
      run_generator ["non_public.search"]

      migration = migration_file("db/migrate/create_non_public_searches.rb")
      expect(migration).to contain(/class CreateNonPublicSearches/)
      expect(migration).to contain(/create_view "non_public.searches"/)
    end
  end
end
