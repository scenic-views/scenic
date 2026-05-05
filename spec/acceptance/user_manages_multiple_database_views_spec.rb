require "acceptance_helper"
require "English"
require "fileutils"

describe "User manages views across multiple databases", :db do
  after(:each) { clean_generated_artifacts }

  it "handles views on secondary database" do
    successfully "rails generate scenic:model analytics --database=secondary"

    expect(Dir["db/secondary_migrate/*_create_analytics.rb"]).not_to be_empty
    expect(File.exist?("db/secondary_views/analytics_v01.sql")).to be true

    write_definition_in_dir "secondary_views", "analytics_v01", "SELECT 'data'::text AS value"
    successfully "rake db:migrate:secondary"
    verify_result "Analytic.take.value", "data"

    successfully "rails generate scenic:view analytics --database=secondary"
    verify_identical_view_definitions_in_dir "secondary_views", "analytics_v01", "analytics_v02"

    write_definition_in_dir "secondary_views", "analytics_v02", "SELECT 'new_data'::text AS value"
    successfully "rake db:migrate:secondary"
    verify_result "Analytic.take.value", "new_data"

    successfully "rake db:rollback:secondary"
    successfully "rake db:rollback:secondary"
    successfully "rails destroy scenic:model analytics --database=secondary"
  end

  it "keeps views on default and secondary databases separate" do
    successfully "rails generate scenic:view reports"
    write_definition "reports_v01", "SELECT 'default_data'::text AS result"

    successfully "rails generate scenic:view metrics --database=secondary"
    write_definition_in_dir "secondary_views", "metrics_v01", "SELECT 'secondary_data'::text AS result"

    expect(Dir["db/migrate/*_create_reports.rb"]).not_to be_empty
    expect(Dir["db/secondary_migrate/*_create_metrics.rb"]).not_to be_empty

    expect(File.exist?("db/views/reports_v01.sql")).to be true
    expect(File.exist?("db/secondary_views/metrics_v01.sql")).to be true

    successfully "rake db:rollback:primary"
    successfully "rake db:rollback:secondary"
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

  def clean_generated_artifacts
    FileUtils.rm_rf("db/secondary_views")
    FileUtils.rm_rf("db/secondary_migrate")
    Dir.glob("db/views/{analytics,reports,metrics}_v*.sql").each { |f| FileUtils.rm_f(f) }
    Dir.glob("db/migrate/*_create_{analytics,reports,metrics}.rb").each { |f| FileUtils.rm_f(f) }
    Dir.glob("app/models/{analytic,report,metric}.rb").each { |f| FileUtils.rm_f(f) }
  end
end
