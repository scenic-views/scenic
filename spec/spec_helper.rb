ENV["RAILS_ENV"] = "test"
require "active_record"
require "database_cleaner"
require "yaml"

require File.expand_path("../dummy/config/environment", __FILE__)
require "support/dummy_app_setup"

RSpec.configure do |config|
  config.order = "random"
  DatabaseCleaner.strategy = :transaction

  config.around(:each) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end
end
