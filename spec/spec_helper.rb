ENV["RAILS_ENV"] = "test"
require "database_cleaner"

require File.expand_path("dummy/config/environment", __dir__)
require "support/rails_configuration_helpers"
require "support/generator_spec_setup"
require "support/view_definition_helpers"

RSpec.configure do |config|
  config.order = "random"
  config.include ViewDefinitionHelpers
  config.include RailsConfigurationHelpers
  DatabaseCleaner.strategy = :transaction

  config.around(:each, db: true) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end

  if defined? ActiveSupport::Testing::Stream
    config.include ActiveSupport::Testing::Stream
  end
end
