require "scenic/configuration"
require "scenic/adapters/postgres"
require "scenic/command_recorder"
require "scenic/definition"
require "scenic/railtie"
require "scenic/schema_dumper"
require "scenic/statements"
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

  # The current database adapter used by Scenic.
  #
  # This defaults to {Adapters::Postgres} but can be overridden
  # via {Configuration}.
  def self.database
    configuration.database
  end

  # The current path for the views files.
  #
  # This defaults to 'db/views', but can be overridden
  # via {Configuration}.
  def self.views_path
    configuration.views_path
  end
end
