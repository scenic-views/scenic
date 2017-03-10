require "spec_helper"

class Search < ActiveRecord::Base; end

describe Scenic::SchemaDumper, :db do
  it "dumps a create_view for a view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches, sql_definition: view_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string
    expect(output).to include "create_view :searches"
    expect(output).to include view_definition

    Search.connection.drop_view :searches

    silence_stream(STDOUT) { eval(output) }

    expect(Search.first.haystack).to eq "needle"
  end

  context "with views in non public schemas" do
    it "dumps a create_view including namespace for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      Search.connection.execute "CREATE SCHEMA scenic; SET search_path TO scenic, public"
      Search.connection.create_view :"scenic.searches", sql_definition: view_definition
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string
      expect(output).to include "create_view :'scenic.searches',"

      Search.connection.drop_view :'scenic.searches'
    end
  end

  context "with dependent views " do
    it "dumps create_view sorted alphabetically" do
      Search.connection.execute("CREATE SCHEMA scenic")
      Search.connection.execute("SET search_path TO scenic, public")

      views = {
        "scenic.view1": "SELECT 'needle1'::text AS haystack",
        "scenic.view2": "SELECT 'needle2'::text AS haystack",
        "scenic.view1_1": "SELECT * FROM scenic.view1",
        "scenic.view1_2": "SELECT * FROM scenic.view1",
      }

      expected_order = %w(
        scenic.view1
        scenic.view1_1
        scenic.view1_2
        scenic.view2
      )

      views.each do |name, definition|
        Search.connection.create_view(name, sql_definition: definition)
      end

      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string

      views.each do |name, _|
        expect(output).to include "create_view :'#{name}',"
      end

      create_views = output.lines.grep(/create_view :/)
      order = create_views.map { |line| line.scan(/scenic\.[a-z_0-9]+/).first }

      expect(order).to eq(expected_order)

      views.keys.reverse.each do |name|
        Search.connection.drop_view(name)
      end
    end
  end
end
