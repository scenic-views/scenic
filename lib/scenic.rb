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
    ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Scenic::Statements)
    ActiveRecord::Migration::CommandRecorder.send(:include, Scenic::CommandRecorder)
    ActiveRecord::SchemaDumper.send(:include, Scenic::SchemaDumper)
  end

  def self.database
    Scenic::Adapters::Postgres
  end
end
