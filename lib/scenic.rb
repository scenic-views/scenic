require "scenic/configuration"
require "scenic/adapters/postgres"
require "scenic/command_recorder"
require "scenic/definition"
require "scenic/railtie"
require "scenic/schema_view_dumper"
require "scenic/schema_function_dumper"
require "scenic/statements"
require "scenic/version"
require "scenic/view"
require "scenic/function"
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
    ActiveRecord::SchemaDumper.prepend Scenic::SchemaFunctionDumper
    ActiveRecord::SchemaDumper.prepend Scenic::SchemaViewDumper
  end

  # The current database adapter used by Scenic.
  #
  # This defaults to {Adapters::Postgres} but can be overridden
  # via {Configuration}.
  def self.database
    configuration.database
  end
end
