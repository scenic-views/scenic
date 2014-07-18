ENV["RAILS_ENV"] = "test"
require "active_record"
require "database_cleaner"
require "yaml"
require File.expand_path("../dummy/config/environment", __FILE__)

RSpec.configure do |config|
  DatabaseCleaner.strategy = :transaction
  config.around(:each, db: true) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end
end
