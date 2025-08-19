ENV["RAILS_ENV"] = "test"
require "database_cleaner"

require File.expand_path("dummy/config/environment", __dir__)

Dir.glob("#{__dir__}/support/**/*.rb").each { |f| require f }

RSpec.configure do |config|
  config.order = "random"
  config.include DatabaseSchemaHelpers
  config.include ViewDefinitionHelpers
  config.include RailsConfigurationHelpers
  DatabaseCleaner.strategy = :transaction

  config.around(:each, db: true) do |example|
    case ActiveRecord.gem_version
    when Gem::Requirement.new(">= 7.2")
      ActiveRecord::SchemaMigration
        .new(ActiveRecord::Tasks::DatabaseTasks.migration_connection_pool)
        .create_table
    when Gem::Requirement.new("~> 7.1.0")
      ActiveRecord::SchemaMigration
        .new(ActiveRecord::Tasks::DatabaseTasks.migration_connection)
        .create_table
    when Gem::Requirement.new("< 7.1")
      ActiveRecord::SchemaMigration.create_table
    end

    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
    
    # Clean up any cascade test views that might persist
    connection = ActiveRecord::Base.connection
    %w[cascade_reports cascade_summary cascade_solos cascade_bases cascade_dependent].each do |view|
      connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{view} CASCADE") rescue nil
    end
  end

  config.before(:each, silence: true) do |example|
    allow_any_instance_of(ActiveRecord::Migration).to receive(:say)
  end

  if defined? ActiveSupport::Testing::Stream
    config.include ActiveSupport::Testing::Stream
  end
end
