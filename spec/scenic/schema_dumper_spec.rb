require "spec_helper"

class Search < ActiveRecord::Base; end

class SearchInAHaystack < ActiveRecord::Base
  self.table_name = '"search in a haystack"'
end

describe Scenic::SchemaDumper, :db do
  it "dumps a create_view for a view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches, sql_definition: view_definition
    stream = StringIO.new

    dump_schema(stream)

    output = stream.string

    expect(output).to include 'create_view "searches", sql_definition: <<-SQL'
    expect(output).to include view_definition

    Search.connection.drop_view :searches

    silence_stream($stdout) { eval(output) } # standard:disable Security/Eval

    expect(Search.first.haystack).to eq "needle"
  end

  it "accurately dumps create view statements with a regular expression" do
    view_definition = "SELECT 'needle'::text AS haystack WHERE 'a2z' ~ '\\d+'"
    Search.connection.create_view :searches, sql_definition: view_definition
    stream = StringIO.new

    dump_schema(stream)

    output = stream.string
    expect(output).to include "~ '\\\\d+'::text"

    Search.connection.drop_view :searches
    silence_stream($stdout) { eval(output) } # standard:disable Security/Eval

    expect(Search.first.haystack).to eq "needle"
  end

  it "dumps a create_view for a materialized view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches, materialized: true, sql_definition: view_definition
    stream = StringIO.new

    dump_schema(stream)

    output = stream.string

    expect(output).to include 'create_view "searches", materialized: true, sql_definition: <<-SQL'
    expect(output).to include view_definition
  end

  context "with views in non public schemas" do
    it "dumps a create_view including namespace for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      Search.connection.execute "CREATE SCHEMA scenic; SET search_path TO scenic, public"
      Search.connection.create_view :"scenic.searches", sql_definition: view_definition
      stream = StringIO.new

      dump_schema(stream)

      output = stream.string
      expect(output).to include 'create_view "scenic.searches",'

      Search.connection.drop_view :"scenic.searches"
    end

    it "sorts dependency order when views exist in a non-public schema" do
      Search.connection.execute("CREATE SCHEMA IF NOT EXISTS scenic; SET search_path TO public, scenic")
      Search.connection.execute("CREATE VIEW scenic.apples AS SELECT 1;")
      Search.connection.execute("CREATE VIEW scenic.bananas AS SELECT 2;")
      Search.connection.execute("CREATE OR REPLACE VIEW scenic.apples AS SELECT * FROM scenic.bananas;")
      stream = StringIO.new

      dump_schema(stream)
      views = stream.string.lines.grep(/create_view/).map do |view_line|
        view_line.match('create_view "(?<name>.*)"')[:name]
      end
      expect(views).to eq(%w[scenic.bananas scenic.apples])

      Search.connection.execute("DROP SCHEMA IF EXISTS scenic CASCADE; SET search_path TO public")
    end
  end

  it "handles active record table name prefixes and suffixes" do
    with_affixed_tables(prefix: "a_", suffix: "_z") do
      view_definition = "SELECT 'needle'::text AS haystack"
      Search.connection.create_view :a_searches_z, sql_definition: view_definition
      stream = StringIO.new

      dump_schema(stream)

      output = stream.string

      expect(output).to include 'create_view "searches"'
    end
  end

  it "ignores tables internal to Rails" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches, sql_definition: view_definition
    stream = StringIO.new

    dump_schema(stream)

    output = stream.string

    expect(output).to include 'create_view "searches"'
    expect(output).not_to include "pg_stat_statements_info"
    expect(output).not_to include "schema_migrations"
  end

  context "with views using unexpected characters in name" do
    it "dumps a create_view for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      Search.connection.create_view '"search in a haystack"', sql_definition: view_definition
      stream = StringIO.new

      dump_schema(stream)

      output = stream.string
      expect(output).to include 'create_view "\"search in a haystack\"",'
      expect(output).to include view_definition

      Search.connection.drop_view :'"search in a haystack"'

      silence_stream($stdout) { eval(output) } # standard:disable Security/Eval

      expect(SearchInAHaystack.take.haystack).to eq "needle"
    end
  end

  context "with views using unexpected characters, name including namespace" do
    it "dumps a create_view for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      Search.connection.execute(
        "CREATE SCHEMA scenic; SET search_path TO scenic, public"
      )
      Search.connection.create_view 'scenic."search in a haystack"',
        sql_definition: view_definition
      stream = StringIO.new

      dump_schema(stream)

      output = stream.string
      expect(output).to include 'create_view "scenic.\"search in a haystack\"",'
      expect(output).to include view_definition

      Search.connection.drop_view :'scenic."search in a haystack"'

      case ActiveRecord.gem_version
      when Gem::Requirement.new(">= 7.1")
        Search.connection.drop_schema "scenic"
      end

      silence_stream($stdout) { eval(output) } # standard:disable Security/Eval

      expect(SearchInAHaystack.take.haystack).to eq "needle"
    end
  end
end
