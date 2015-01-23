require "rails/railtie"

module Scenic
  class Railtie < Rails::Railtie
    initializer "scenic.load" do
      ActiveSupport.on_load :active_record do
        Scenic.load

        ActiveRecord::SchemaDumper.ignore_tables += Scenic.database.extensions
      end
    end
  end
end
