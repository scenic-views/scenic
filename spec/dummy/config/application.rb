require File.expand_path("../boot", __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"

Bundler.require(*Rails.groups)
require "scenic"

module Dummy
  class Application < Rails::Application
  end
end
