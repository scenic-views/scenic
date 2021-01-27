require "rails/generators"
require "rails/generators/active_record"
require "generators/scenic/materializable"
require "scenic/definition"
require "scenic/definitions"

module Scenic
  module Generators
    # @api private
    class ViewGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      include Scenic::Generators::Materializable
      source_root File.expand_path("templates", __dir__)

      def create_views_directory
        unless Scenic.configuration.definitions_path.exist?
          empty_directory(Scenic.configuration.definitions_path)
        end
      end

      def create_view_definition
        if creating_new_view?
          create_file definition.path
        else
          copy_file previous_definition.path, definition.path
        end
      end

      def create_migration_file
        if creating_new_view? || destroying_initial_view?
          migration_template(
            "db/migrate/create_view.erb",
            "db/migrate/create_#{plural_file_name}.rb",
          )
        else
          version = definition.version
          migration_template(
            "db/migrate/update_view.erb",
            "db/migrate/update_#{plural_file_name}_to_version_#{version}.rb",
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def migration_class_name
          if creating_new_view?
            "Create#{class_name.tr('.', '').pluralize}"
          else
            "Update#{class_name.pluralize}ToVersion#{definition.version}"
          end
        end

        def activerecord_migration_class
          if ActiveRecord::Migration.respond_to?(:current_version)
            "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
          else
            "ActiveRecord::Migration"
          end
        end
      end

      private

      alias singular_name file_name

      def file_name
        super.tr(".", "_")
      end

      def definitions
        @definitions ||= Scenic::Definitions.new(plural_file_name)
      end

      def creating_new_view?
        definitions.none?
      end

      def definition
        previous_version = previous_definition.version
        version = destroying? ? previous_version : previous_version.next
        Scenic::Definition.new(plural_file_name, version)
      end

      def previous_definition
        definitions.max || Scenic::Definition.new(plural_file_name, 0)
      end

      def destroying?
        behavior == :revoke
      end

      def formatted_plural_name
        if plural_name.include?(".")
          "\"#{plural_name}\""
        else
          ":#{plural_name}"
        end
      end

      def create_view_options
        if materialized?
          ", materialized: #{no_data? ? '{ no_data: true }' : true}"
        else
          ""
        end
      end

      def destroying_initial_view?
        destroying? && definition.version == 1
      end
    end
  end
end
