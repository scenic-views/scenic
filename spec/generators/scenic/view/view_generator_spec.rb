require "spec_helper"
require "generators/scenic/view/view_generator"

describe Scenic::Generators::ViewGenerator, :generator do
  it "creates a view definition file" do
    run_generator ["searches"]
    view_definition = file("db/views/searches_v1.sql")
    expect(view_definition).to exist
  end

  it "creates a migration to create the view" do
    run_generator ["searches"]
    migration = file("db/migrate/create_searches.rb")
    expect(migration).to be_a_migration
  end
end
