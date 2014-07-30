require "scenic/version"
require "scenic/railtie"
require "scenic/active_record/statements"
require "scenic/active_record/command_recorder"

module Scenic
  def self.load
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
      include Scenic::ActiveRecord::Statements
    end

    ::ActiveRecord::Migration::CommandRecorder.class_eval do
      include Scenic::ActiveRecord::CommandRecorder
    end
  end
end
