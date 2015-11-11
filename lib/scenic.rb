require "scenic/configuration"
require "scenic/adapters/postgres"
require "scenic/command_recorder"
require "scenic/definition"
require "scenic/railtie"
require "scenic/schema_dumper"
require "scenic/statements"
require "scenic/version"
require "scenic/view"

module Scenic
  def self.load
    ActiveRecord::ConnectionAdapters::AbstractAdapter.include Scenic::Statements
    ActiveRecord::Migration::CommandRecorder.include Scenic::CommandRecorder
    ActiveRecord::SchemaDumper.prepend Scenic::SchemaDumper
  end

  # The current database adapter used by Scenic.
  # This defaults to [Adapters::Postgres] but can be overridden
  # via [Configuration].
  def self.database
    configuration.database
  end
end
