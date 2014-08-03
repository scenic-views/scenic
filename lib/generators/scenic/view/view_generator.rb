require "rails/generators"
require "rails/generators/active_record"

module Scenic
  module Generators
    class ViewGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)
      argument :view_name, type: :string

      def create_view_definition
        create_file "db/views/#{view_name}_v1.sql"
      end

      def create_migration_file
        migration_template(
          "db/migrate/create_view.erb",
          "db/migrate/create_#{view_name}.rb"
        )
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
