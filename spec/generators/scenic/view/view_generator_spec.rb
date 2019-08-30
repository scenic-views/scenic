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
        "db/migrate/update_aired_episodes_to_version_2.rb",
      )
      expect(migration).to contain "materialized: true"
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
