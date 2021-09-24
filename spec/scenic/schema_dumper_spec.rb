require "spec_helper"

class Search < ActiveRecord::Base; end

class SearchInAHaystack < ActiveRecord::Base
  self.table_name = '"search in a haystack"'
end

describe Scenic::SchemaDumper, :db do
  let(:conn) { Search.connection }
  let(:output) do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(conn, stream)
    stream.string
  end

  it "dumps a create_view for a view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    conn.create_view :searches, sql_definition: view_definition

    expect(output).to include 'create_view "searches", sql_definition: <<-SQL'
    expect(output).to include view_definition

    conn.drop_view :searches

    silence_stream(STDOUT) { eval(output) }

    expect(Search.first.haystack).to eq "needle"
  end

  it "dumps a create_view for a materialized view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    conn.create_view :searches,
      materialized: true, sql_definition: view_definition

    expect(output).to include 'create_view "searches", materialized: true, sql_definition: <<-SQL'
    expect(output).to include view_definition
  end

  context "with views in non public schemas" do
    it "dumps a create_view including namespace for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      conn.execute "CREATE SCHEMA scenic; SET search_path TO scenic, public"
      conn.create_view :"scenic.searches", sql_definition: view_definition

      expect(output).to include 'create_view "scenic.searches",'

      conn.drop_view :'scenic.searches'
    end
  end

  it "ignores tables internal to Rails" do
    view_definition = "SELECT 'needle'::text AS haystack"
    conn.create_view :searches, sql_definition: view_definition

    expect(output).to include 'create_view "searches"'
    expect(output).not_to include "ar_internal_metadata"
    expect(output).not_to include "schema_migrations"
  end

  context "with views using unexpected characters in name" do
    it "dumps a create_view for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      conn.create_view '"search in a haystack"',
        sql_definition: view_definition

      expect(output).to include 'create_view "\"search in a haystack\"",'
      expect(output).to include view_definition

      conn.drop_view :'"search in a haystack"'

      silence_stream(STDOUT) { eval(output) }

      expect(SearchInAHaystack.take.haystack).to eq "needle"
    end
  end

  context "with views using unexpected characters, name including namespace" do
    it "dumps a create_view for a view in the database" do
      view_definition = "SELECT 'needle'::text AS haystack"
      conn.execute(
        "CREATE SCHEMA scenic; SET search_path TO scenic, public",
      )
      conn.create_view 'scenic."search in a haystack"',
        sql_definition: view_definition

      expect(output).to include 'create_view "scenic.\"search in a haystack\"",'
      expect(output).to include view_definition

      conn.drop_view :'scenic."search in a haystack"'

      silence_stream(STDOUT) { eval(output) }

      expect(SearchInAHaystack.take.haystack).to eq "needle"
    end
  end

  context "with viewes ordered by name" do
    let(:views) do
      output.lines.grep(/create_view/).map do |view_line|
        view_line.match('create_view "(?<name>.*)"')[:name]
      end
    end

    context "without dependencies" do
      it "sorts views without dependencies" do
        conn.create_view "cucumber_needles",
          sql_definition: "SELECT 'kukumbas'::text as needle"
        conn.create_view "vip_needles",
          sql_definition: "SELECT 'vip'::text as needle"
        conn.create_view "none_needles",
          sql_definition: "SELECT 'none_needles'::text as needle"

        # Same here, no dependencies among existing views, all views are sorted
        sorted_views = %w[cucumber_needles vip_needles none_needles].sort

        expect(views).to eq(sorted_views)
      end
    end

    context "with dependencies" do
      it "sorts according to dependencies" do
        conn.create_table(:tasks) { |t| t.integer :performer_id }
        conn.create_table(:notes) do |t|
          t.text :title
          t.integer :author_id
        end
        conn.create_table(:users) { |t| t.text :nickname }
        conn.create_table(:roles) do |t|
          t.text :name
          t.integer :user_id
        end

        conn.create_view "recent_tasks",
          sql_definition: <<-SQL
            SELECT id, performer_id from tasks where id > 42
          SQL
        conn.create_view "old_roles",
          sql_definition: <<-SQL
           SELECT id, name from roles where id > 56
          SQL
        conn.create_view "nirvana_notes",
          sql_definition: <<-SQL
           SELECT notes.id, notes.title, notes.author_id, old_roles.name FROM notes
           JOIN old_roles ON notes.author_id = old_roles.id
          SQL
        conn.create_view "angry_zombies",
          sql_definition: <<-SQL
            SELECT users.nickname, recent_tasks.id as task_id, nirvana_notes.title as talk FROM users
            JOIN roles ON roles.user_id = users.id
            JOIN nirvana_notes ON nirvana_notes.author_id = roles.id
            JOIN recent_tasks ON recent_tasks.performer_id = roles.id
          SQL
        conn.create_view "doctor_zombies",
          sql_definition: <<-SQL
           SELECT id FROM old_roles WHERE name LIKE '%Dr%'
          SQL
        conn.create_view "xenomorphs",
          sql_definition: <<-SQL
           SELECT id, name FROM roles WHERE name = 'xeno'
          SQL
        conn.create_view "important_messages",
          sql_definition: <<-SQL
            SELECT id, title FROM notes WHERE title LIKE '%NSFW%'
          SQL

        # Converted with https://github.com/ggerganov/dot-to-ascii
        # digraph {
        #   rankdir = "BT";
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
        expect(views).to eq(%w[old_roles nirvana_notes recent_tasks
                               angry_zombies doctor_zombies
                               important_messages xenomorphs])
      end
    end
  end
end
