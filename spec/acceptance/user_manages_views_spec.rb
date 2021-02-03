require "acceptance_helper"
require "English"

describe "User manages views" do
  it "handles simple views" do
    successfully "rails generate scenic:model search_result"
    write_definition "search_results_v01", "SELECT 'needle'::text AS term"

    successfully "rake db:migrate"
    verify_result "SearchResult.take.term", "needle"

    successfully "rails generate scenic:view search_results"
    verify_identical_view_definitions "search_results_v01", "search_results_v02"

    write_definition "search_results_v02", "SELECT 'haystack'::text AS term"
    successfully "rake db:migrate"

    successfully "rake db:reset"
    verify_result "SearchResult.take.term", "haystack"

    successfully "rake db:rollback"
    successfully "rake db:rollback"
    successfully "rails destroy scenic:model search_result"
  end

  it "handles materialized views" do
    successfully "rails generate scenic:model child --materialized"
    write_definition "children_v01", "SELECT 'Owen'::text AS name, 5 AS age"

    successfully "rake db:migrate"
    verify_result "Child.take.name", "Owen"

    add_index "children", "name"
    add_index "children", "age"

    successfully "rails runner 'Child.refresh'"

    successfully "rails generate scenic:view child --materialized"
    verify_identical_view_definitions "children_v01", "children_v02"

    write_definition "children_v02", "SELECT 'Elliot'::text AS name"
    successfully "rake db:migrate"

    successfully "rake db:reset"
    verify_result "Child.take.name", "Elliot"
    verify_schema_contains 'add_index "children"'

    successfully "rake db:rollback"
    successfully "rake db:rollback"
    successfully "rails destroy scenic:model child"
  end

  it "handles plural view names gracefully during generation" do
    successfully "rails generate scenic:model search_results --materialized"
    successfully "rails destroy scenic:model search_results --materialized"
  end

  it "handle replacing materialized views" do
    successfully "rails generate scenic:model greeting --materialized"
    write_definition "greetings_v01", "SELECT text 'hi' AS hello"

    successfully "rake db:migrate"
    verify_result "Greeting.take.hello", "hi"

    successfully "rails generate scenic:view greeting_next --materialized"
    write_definition "greeting_nexts_v01", "SELECT text 'welcome' AS hello"

    successfully "rake db:migrate"
    verify_result "Greeting.take.hello", "hi"

    successfully "rails runner 'Scenic.database.refresh_materialized_view(:greeting_nexts)'"

    successfully "rails generate scenic:view greeting --materialized --rename greeting_next"
    verify_identical_view_definitions "greeting_nexts_v01", "greetings_v02"
    replace_into_migration "update_greetings_to_version_2", "rename_view", "replace_view"

    successfully "rake db:migrate"
    verify_result "Greeting.take.hello", "welcome"

    successfully "rails destroy scenic:model greeting"
  end

  def successfully(command)
    `RAILS_ENV=test #{command}`
    expect($CHILD_STATUS.exitstatus).to eq(0), "'#{command}' was unsuccessful"
  end

  def write_definition(file, contents)
    File.open("db/views/#{file}.sql", File::WRONLY) do |definition|
      definition.truncate(0)
      definition.write(contents)
    end
  end

  def verify_result(command, expected_output)
    successfully %{rails runner "#{command} == '#{expected_output}' || exit(1)"}
  end

  def verify_identical_view_definitions(def_a, def_b)
    successfully "cmp db/views/#{def_a}.sql db/views/#{def_b}.sql"
  end

  def add_index(table, column)
    successfully(<<-CMD.strip)
      rails runner 'ActiveRecord::Migration.add_index "#{table}", "#{column}"'
    CMD
  end

  def verify_schema_contains(statement)
    expect(File.readlines("db/schema.rb").grep(/#{statement}/))
      .not_to be_empty, "Schema does not contain '#{statement}'"
  end

  def replace_into_migration(name, pattern, replacement)
    filename = Dir.glob("db/migrate/[0-9]*_#{name}.rb").first

    content = File.read(filename).gsub(pattern, replacement)

    File.write(filename, content)
  end
end
