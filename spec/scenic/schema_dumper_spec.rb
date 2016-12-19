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

  it "sorts the views by name when dumped" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches_b, sql_definition: view_definition
    Search.connection.create_view :searches_c, sql_definition: view_definition
    Search.connection.create_view :searches_a, sql_definition: view_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string
    expect(output).to include "create_view :searches_a"
    expect(output).to include "create_view :searches_b"
    expect(output).to include "create_view :searches_c"
    expect(output).to include view_definition

    a_index = output.lines.find_index { |l| l.include?("searches_a") }
    b_index = output.lines.find_index { |l| l.include?("searches_b") }
    c_index = output.lines.find_index { |l| l.include?("searches_c") }

    expect(a_index).to be < b_index
    expect(b_index).to be < c_index

    Search.connection.drop_view :searches_a
    Search.connection.drop_view :searches_b
    Search.connection.drop_view :searches_c

    silence_stream(STDOUT) { eval(output) }
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
end
