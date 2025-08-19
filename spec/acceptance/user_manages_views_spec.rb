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

    successfully "rails generate scenic:view child --materialized --side-by-side"
    verify_identical_view_definitions "children_v02", "children_v03"

    write_definition "children_v03", "SELECT 'Juniper'::text AS name"
    successfully "rake db:migrate"

    successfully "rake db:reset"
    verify_result "Child.take.name", "Juniper"
    verify_schema_contains 'add_index "children"'

    successfully "rake db:rollback"
    successfully "rake db:rollback"
    successfully "rake db:rollback"
    successfully "rails destroy scenic:model child"
  end

  it "handles plural view names gracefully during generation" do
    successfully "rails generate scenic:model search_results --materialized"
    successfully "rails destroy scenic:model search_results --materialized"
  end

  it "handles materialized views with cascade updates" do
    successfully "rails generate scenic:model cascade_report --materialized"
    write_definition "cascade_reports_v01", "SELECT 'data'::text AS value, 1 AS count"

    successfully "rake db:migrate"
    verify_result "CascadeReport.take.value", "data"

    successfully %{rails runner "
      ActiveRecord::Migration.create_view(
        :cascade_summary, 
        materialized: true, 
        sql_definition: <<-SQL
          SELECT value || '_summary' AS summary, count * 2 AS doubled
          FROM cascade_reports
        SQL
      )
    "}

    verify_result "ActiveRecord::Base.connection.execute('SELECT summary FROM cascade_summary').first['summary']", "data_summary"

    successfully "rails generate scenic:view cascade_report --materialized --cascade"
    verify_identical_view_definitions "cascade_reports_v01", "cascade_reports_v02"

    write_definition "cascade_reports_v02", "SELECT 'updated'::text AS value, 3 AS count"
    successfully "rake db:migrate"

    successfully "rake db:reset"
    verify_result "CascadeReport.take.value", "updated"
    verify_result "ActiveRecord::Base.connection.execute('SELECT summary FROM cascade_summary').first['summary']", "updated_summary"

    successfully %{rails runner "
      ActiveRecord::Base.connection.execute('DROP MATERIALIZED VIEW IF EXISTS cascade_summary CASCADE')
      ActiveRecord::Base.connection.execute('DROP MATERIALIZED VIEW IF EXISTS cascade_reports CASCADE')
    "}
    successfully "rails destroy scenic:model cascade_report"
  end

  it "handles cascade with no dependencies" do
    successfully "rails generate scenic:model cascade_solo --materialized"
    write_definition "cascade_solos_v01", "SELECT 'standalone'::text AS value"

    successfully "rake db:migrate"
    verify_result "CascadeSolo.take.value", "standalone"

    successfully "rails generate scenic:view cascade_solo --materialized --cascade"
    verify_identical_view_definitions "cascade_solos_v01", "cascade_solos_v02"

    write_definition "cascade_solos_v02", "SELECT 'updated_standalone'::text AS value"
    successfully "rake db:migrate"

    successfully "rake db:reset"
    verify_result "CascadeSolo.take.value", "updated_standalone"

    successfully %{rails runner "ActiveRecord::Base.connection.execute('DROP MATERIALIZED VIEW IF EXISTS cascade_solos CASCADE')"}
    successfully "rails destroy scenic:model cascade_solo"
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
end
