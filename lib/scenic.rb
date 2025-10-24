require "scenic/configuration"
require "scenic/adapters/postgres"
require "scenic/command_recorder"
require "scenic/definition"
require "scenic/railtie"
require "scenic/schema_dumper"
require "scenic/statements"
require "scenic/unaffixed_name"
require "scenic/version"
require "scenic/view"
require "scenic/index"

# Scenic adds methods `ActiveRecord::Migration` to create and manage database
# views in Rails applications.
module Scenic
  # Hooks Scenic into Rails.
  #
  # Enables scenic migration methods, migration reversability, and `schema.rb`
  # dumping.
  def self.load
    ActiveRecord::ConnectionAdapters::AbstractAdapter.include Scenic::Statements
    ActiveRecord::Migration::CommandRecorder.include Scenic::CommandRecorder
    ActiveRecord::SchemaDumper.prepend Scenic::SchemaDumper
  end

  # Returns the database adapter for the specified database.
  #
  # This defaults to {Adapters::Postgres} but can be overridden
  # via {Configuration}.
  #
  # @param name [Symbol] the database name (defaults to :default)
  # @return [Scenic::Adapters::Postgres] the database adapter
  def self.database(name = :default)
    configuration.database_adapter(name)
  end
end
