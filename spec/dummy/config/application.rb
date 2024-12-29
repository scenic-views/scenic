require File.expand_path("../boot", __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"

Bundler.require(*Rails.groups)
require "scenic"

module Dummy
  class Application < Rails::Application
    config.cache_classes = true
    config.eager_load = false
    config.active_support.deprecation = :stderr

    if config.active_support.respond_to?(:to_time_preserves_timezone)
      config.active_support.to_time_preserves_timezone = :zone
    end
  end
end
