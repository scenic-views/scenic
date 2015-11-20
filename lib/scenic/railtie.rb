require "rails/railtie"

module Scenic
  # Automatically initializes Scenic in the context of a Rails application when
  # ActiveRecord is loaded.
  #
  # @see Scenic.load
  class Railtie < Rails::Railtie
    initializer "scenic.load" do
      ActiveSupport.on_load :active_record do
        Scenic.load
      end
    end
  end
end
