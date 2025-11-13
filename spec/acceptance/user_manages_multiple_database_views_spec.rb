require "acceptance_helper"
require "English"
require "fileutils"

describe "User manages views across multiple databases", :db do
  it "handles views on secondary database" do
    # Generate a view for the secondary database
    successfully "rails generate scenic:model analytics --database=secondary"

    # Verify the migration was created in a database-specific migration directory
    # Either the configured path (db/secondary_migrate) or the convention
    migrations = Dir["db/**/*_create_analytics.rb"]
    expect(migrations).not_to be_empty
    expect(migrations.first).to match(/db\/(secondary_migrate)\/.*_create_analytics\.rb/)

    # Verify the view definition was created in the secondary database views directory
    expect(File.exist?("db/secondary_views/analytics_v01.sql")).to be true

    # Write a view definition
    write_definition_in_dir "secondary_views", "analytics_v01", "SELECT 'data'::text AS value"
    # successfully "rake db:migrate:secondary"
    successfully "rake db:migrate:secondary"
    verify_result "Analytic.take.value", "data"

    # Verify we can update to a new version
    successfully "rails generate scenic:view analytics --database=secondary"
    verify_identical_view_definitions_in_dir "secondary_views", "analytics_v01", "analytics_v02"

    # Update the view definition
    write_definition_in_dir "secondary_views", "analytics_v02", "SELECT 'new_data'::text AS value"
    successfully "rake db:migrate:secondary"
    verify_result "Analytic.take.value", "new_data"

    # Clean up
    successfully "rake db:rollback:secondary"
    successfully "rake db:rollback:secondary"
    successfully "rails destroy scenic:model analytics --database=secondary"
  end

  it "keeps views on default and secondary databases separate" do
    # Generate view on default database
    successfully "rails generate scenic:view reports"
    write_definition "reports_v01", "SELECT 'default_data'::text AS result"

    # Generate view on secondary database
    successfully "rails generate scenic:view metrics --database=secondary"
    write_definition_in_dir "secondary_views", "metrics_v01", "SELECT 'secondary_data'::text AS result"

    # Verify migrations are in separate directories
    expect(Dir["db/migrate/*_create_reports.rb"]).not_to be_empty
    # Check for either configured path or convention-based path
    secondary_migrations = Dir["db/**/*_create_metrics.rb"].select { |p| p !~ /db\/migrate\/[^\/]*_create_metrics\.rb/ }
    expect(secondary_migrations).not_to be_empty

    # Verify view definitions are in separate directories
    expect(File.exist?("db/views/reports_v01.sql")).to be true
    expect(File.exist?("db/secondary_views/metrics_v01.sql")).to be true

    successfully "rake db:rollback:primary"
    successfully "rake db:rollback:secondary"
    # Clean up
    successfully "rails destroy scenic:view reports"
    successfully "rails destroy scenic:view metrics --database=secondary"
  end

  private

  def verify_result(command, expected_output)
    successfully %{rails runner "#{command} == '#{expected_output}' || exit(1)"}
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

  def write_definition_in_dir(dir, filename, sql)
    FileUtils.mkdir_p("db/#{dir}")
    File.open("db/#{dir}/#{filename}.sql", File::WRONLY | File::CREAT) do |definition|
      definition.truncate(0)
      definition.write(sql)
    end
  end

  def verify_identical_view_definitions_in_dir(dir, first, second)
    successfully "cmp db/#{dir}/#{first}.sql db/#{dir}/#{second}.sql"
  end
end
