require "scenic/version"
require "scenic/railtie"
require "scenic/active_record/statements"

module Scenic
  def self.load
    ::ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
      include Scenic::ActiveRecord::Statements
    end
  end
end
