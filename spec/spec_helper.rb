ENV["RAILS_ENV"] = "test"
require "database_cleaner"

require File.expand_path("../dummy/config/environment", __FILE__)
require "support/view_definition_helpers"

RSpec.configure do |config|
  config.order = "random"
  config.include ViewDefinitionHelpers
  DatabaseCleaner.strategy = :transaction

  config.around(:each, db: true) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end
end
