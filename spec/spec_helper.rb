ENV["RAILS_ENV"] = 'test'
require 'database_cleaner'

require File.expand_path('../dummy/config/environment', __FILE__)
require 'support/generator_spec_setup'
require 'support/definition_helpers'

RSpec.configure do |config|
  config.order = "random"
  config.include DefinitionHelpers
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
