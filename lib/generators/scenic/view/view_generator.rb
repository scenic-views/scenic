require "rails/generators"
require "rails/generators/active_record"

module Scenic
  module Generators
    class ViewGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      def create_view_definition
        create_file definition.path
      end

      def create_migration_file
        if updating_existing_view?
          migration_template(
            "db/migrate/update_view.erb",
            "db/migrate/update_#{plural_file_name}_v#{definition.version}.rb"
          )
        else
          migration_template(
            "db/migrate/create_view.erb",
            "db/migrate/create_#{plural_file_name}.rb"
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @previous_version ||=
            Dir.entries(Rails.root.join(*%w(db views)))
              .map { |name| version_regex.match(name).try(:[], "version").to_i }
              .max
        end

        def version
          @version ||= previous_version.next
        end

        def migration_class_name
          if updating_existing_view?
            "Update#{class_name.pluralize}ToVersion#{version}"
          else
            super
          end
        end
      end

      private

      def version_regex
        /\A#{plural_file_name}_v(?<version>\d+)\.sql\z/
      end

      def updating_existing_view?
        previous_version > 0
      end

      def definition
        Scenic::Definition.new(plural_file_name, version)
      end
    end
  end
end
