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
  end

  if defined? ActiveSupport::Testing::Stream
    config.include ActiveSupport::Testing::Stream
  end
end
