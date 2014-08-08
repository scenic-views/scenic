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
    ActiveRecord::SchemaDumper.include Scenic::SchemaDumper
  end

  def self.database
    Scenic::Adapters::Postgres
  end
end
