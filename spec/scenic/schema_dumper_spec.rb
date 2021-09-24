require "spec_helper"

class Search < ActiveRecord::Base; end

class SearchInAHaystack < ActiveRecord::Base
  self.table_name = '"search in a haystack"'
end

describe Scenic::SchemaDumper, :db do
  let(:output) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(Search.connection, stream)
    stream.string
  end

  it "dumps a create_view for a view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches, sql_definition: view_definition

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

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string
    expect(output).to include "~ '\\\\d+'::text"

    Search.connection.drop_view :searches
    silence_stream($stdout) { eval(output) } # standard:disable Security/Eval

    expect(Search.first.haystack).to eq "needle"
  end

  it "dumps a create_view for a materialized view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches,
      materialized: true, sql_definition: view_definition

    expect(output).to include 'create_view "searches", materialized: true, sql_definition: <<-SQL'
    expect(output).to include view_definition
  end

  context "with views in non public schemas" do
    it "dumps a create_view including namespace for a view in the database" do
      Search.connection.create_view :"scenic.searches",
        sql_definition: "SELECT 'needle'::text AS haystack"

      expect(output).to include 'create_view "scenic.searches",'
    end

    it "sorts dependency order when views exist in a non-public schema" do
      Search.connection.execute("CREATE VIEW scenic.apples AS SELECT 1;")
      Search.connection.execute("CREATE VIEW scenic.bananas AS SELECT 2;")
      Search.connection.execute("CREATE OR REPLACE VIEW scenic.apples AS SELECT * FROM scenic.bananas;")
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      views = stream.string.lines.grep(/create_view/).map do |view_line|
        view_line.match('create_view "(?<name>.*)"')[:name]
      end
      expect(views).to eq(%w[scenic.bananas scenic.apples])
    end

    before(:each) do
      Search.connection.execute(
        "CREATE SCHEMA IF NOT EXISTS scenic; SET search_path TO public, scenic"
      )
    end

    after(:each) do
      Search.connection.execute(
        "DROP SCHEMA IF EXISTS scenic CASCADE; SET search_path TO public"
      )
    end
  end

  it "handles active record table name prefixes and suffixes" do
    with_affixed_tables(prefix: "a_", suffix: "_z") do
      view_definition = "SELECT 'needle'::text AS haystack"
      Search.connection.create_view :a_searches_z, sql_definition: view_definition
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(Search.connection, stream)

      output = stream.string

      expect(output).to include 'create_view "searches"'
    end
  end

  it "ignores tables internal to Rails" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches, sql_definition: view_definition

    expect(output).to include 'create_view "searches"'
    expect(output).not_to include "pg_stat_statements_info"
    expect(output).not_to include "schema_migrations"
  end

  context "with views using unexpected characters in name" do
    it "dumps a create_view for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      Search.connection.create_view '"search in a haystack"',
        sql_definition: view_definition

      expect(output).to include 'create_view "\"search in a haystack\"",'
      expect(output).to include view_definition

      Search.connection.drop_view :"\"search in a haystack\""

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

      expect(output).to include 'create_view "scenic.\"search in a haystack\"",'
      expect(output).to include view_definition

      Search.connection.drop_view :"scenic.\"search in a haystack\""

      silence_stream($stdout) { eval(output) } # standard:disable Security/Eval

      expect(SearchInAHaystack.take.haystack).to eq "needle"
    end
  end

  context "with views ordered by name" do
    it "sorts views without dependencies" do
      Search.connection.create_view "cucumber_needles",
        sql_definition: "SELECT 'kukumbas'::text AS needle"
      Search.connection.create_view "vip_needles",
        sql_definition: "SELECT 'vip'::text AS needle"
      Search.connection.create_view "none_needles",
        sql_definition: "SELECT 'none_needles'::text AS needle"

      # Same here, no dependencies among existing views, all views are sorted
      sorted_views = %w[cucumber_needles vip_needles none_needles].sort

      expect(views_in_output_order).to eq(sorted_views)
    end

    it "sorts according to dependencies" do
      Search.connection.create_table(:tasks) { |t| t.integer :performer_id }
      Search.connection.create_table(:notes) do |t|
        t.text :title
        t.integer :author_id
      end
      Search.connection.create_table(:users) { |t| t.text :nickname }
      Search.connection.create_table(:roles) do |t|
        t.text :name
        t.integer :user_id
      end

      Search.connection.create_view "recent_tasks", sql_definition: <<-SQL
        SELECT id, performer_id FROM tasks WHERE id > 42
      SQL
      Search.connection.create_view "old_roles", sql_definition: <<-SQL
        SELECT id, name FROM roles WHERE id > 56
      SQL
      Search.connection.create_view "nirvana_notes", sql_definition: <<-SQL
        SELECT notes.id, notes.title, notes.author_id, old_roles.name
        FROM notes
        JOIN old_roles ON notes.author_id = old_roles.id
      SQL
      Search.connection.create_view "angry_zombies", sql_definition: <<-SQL
        SELECT
          users.nickname,
            recent_tasks.id AS task_id,
            nirvana_notes.title AS talk
        FROM users
        JOIN roles ON roles.user_id = users.id
        JOIN nirvana_notes ON nirvana_notes.author_id = roles.id
        JOIN recent_tasks ON recent_tasks.performer_id = roles.id
      SQL
      Search.connection.create_view "doctor_zombies", sql_definition: <<-SQL
        SELECT id FROM old_roles WHERE name LIKE '%dr%'
      SQL
      Search.connection.create_view "xenomorphs", sql_definition: <<-SQL
        SELECT id, name FROM roles WHERE name = 'xeno'
      SQL
      Search.connection.create_view "important_messages", sql_definition: <<-SQL
        SELECT id, title FROM notes WHERE title LIKE '%important%'
      SQL

      # converted with https://github.com/ggerganov/dot-to-ascii
      # digraph {
      #   rankdir = "bt";
      #   xenomorphs;
      #   important_messages;
      #   doctor_zombies -> old_roles;
      #   nirvana_notes -> old_roles;
      #   angry_zombies -> nirvana_notes;
      #   angry_zombies -> recent_tasks;
      # }
      #
      # +--------------------+
      # |   doctor_zombies   |
      # +--------------------+
      #   |
      #   |
      #   v
      # +--------------------+
      # |     old_roles      |
      # +--------------------+
      #   ^
      #   |
      #   |
      # +--------------------+
      # |   nirvana_notes    |
      # +--------------------+
      #   ^
      #   |
      #   |
      # +--------------------+     +--------------+
      # |   angry_zombies    | --> | recent_tasks |
      # +--------------------+     +--------------+
      # +--------------------+
      # | important_messages |
      # +--------------------+
      # +--------------------+
      # |     xenomorphs     |
      # +--------------------+
      expect(views_in_output_order).to eq(%w[
        old_roles
        nirvana_notes
        recent_tasks
        angry_zombies
        doctor_zombies
        important_messages
        xenomorphs
      ])
    end

    def views_in_output_order
      output.lines.grep(/create_view/).map do |view_line|
        view_line.match('create_view "(?<name>.*)"')[:name]
      end
    end
  end
end
