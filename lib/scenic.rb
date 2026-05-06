require "scenic/configuration"
require "scenic/adapters/postgres"
require "scenic/command_recorder"
require "scenic/database_paths"
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

  # Returns the Scenic adapter registered for the given database name.
  #
  # The `:default` adapter is always registered and defaults to an instance of
  # {Adapters::Postgres}. Other names are registered via {Scenic.configure}:
  #
  #     Scenic.configure do |config|
  #       config.databases[:secondary] = Scenic::Adapters::Postgres.new(SecondaryRecord)
  #     end
  #
  # @param name [Symbol] the database name (defaults to :default)
  # @raise [Scenic::UnknownDatabaseError] when `name` is not the default and is
  #   unregistered.
  # @return [Scenic::Adapters::Postgres] the database adapter
  def self.database(name = :default)
    configuration.database_adapter(name)
  end

  # Returns a Scenic adapter scoped to the given connectable.
  #
  # The connectable is anything that responds to `.connection`, but is typically
  # an ActiveRecord model class. This is the connection-first entry point used
  # by generated materialized view models so that operations on, say, a
  # `--database=secondary` model run against the secondary connection without
  # consulting Scenic.configuration.
  #
  # @param connectable [#connection] An object that returns the connection for
  #   fScenic to use.
  # @return [Scenic::Adapters::Postgres]
  def self.adapter_for(connectable)
    Adapters::Postgres.new(connectable)
  end
end
