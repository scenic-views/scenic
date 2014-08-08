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

  it "accepts a SQL option to put in the view definition file" do
    sql = "SELECT foo FROM bar"
    view_definition = file("db/views/searches_v01.sql")
    run_generator ["search", "--sql #{sql}"]

    expect(view_definition).to contain(sql)
  end

  it "updates an existing view" do
    migration = file("db/migrate/update_searches_to_version_2.rb")
    view_definition = file("db/views/searches_v02.sql")
    allow(Dir).to receive(:entries)
      .and_return(["searches_v01.sql"])

    run_generator ["search"]

    expect(migration).to be_a_migration
    expect(view_definition).to exist
  end
end
