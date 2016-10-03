require 'rails/generators'
require 'rails/generators/active_record'
require 'generators/scenic/materializable'

module Scenic
  module Generators
    # @api private
    class FunctionGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      def create_functions_directory
        unless functions_directory_path.exist?
          empty_directory(functions_directory_path)
        end
      end

      def create_function_definition
        if creating_new_function?
          create_file definition.path
        else
          copy_file previous_definition.full_path, definition.full_path
        end
      end

      def create_migration_file
        if creating_new_function? || destroying_initial_function?
          migration_template(
            'db/migrate/create_function.erb',
            "db/migrate/create_#{formatted_file_name}.rb",
          )
        else
          migration_template(
            'db/migrate/update_function.erb',
            "db/migrate/update_#{formatted_file_name}_to_version_#{version}.rb",
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @previous_version ||=
            Dir.entries(functions_directory_path)
              .map { |name| version_regex.match(name).try(:[], 'version').to_i }
              .max
        end

        def version
          @version ||= destroying? ? previous_version : previous_version.next
        end

        def migration_class_name
          if creating_new_function?
            "Create#{class_name.gsub('.', '')}"
          else
            "Update#{class_name}ToVersion#{version}"
          end
        end
      end

      private

      def functions_directory_path
        @functions_directory_path ||= Rails.root.join(*%w(db functions))
      end

      def version_regex
        /\A#{formatted_file_name}_v(?<version>\d+)\.sql\z/
      end

      def creating_new_function?
        previous_version == 0
      end

      def definition
        Scenic::Definition.new(formatted_file_name, version, :function)
      end

      def previous_definition
        Scenic::Definition.new(formatted_file_name, previous_version, :function)
      end

      def formatted_file_name
        @plural_file_name ||= file_name.gsub('.', '_')
      end

      def destroying?
        behavior == :revoke
      end

      def formatted_name
        if singular_name.include?(".")
          "\"#{singular_name}\""
        else
          ":#{singular_name}"
        end
      end

      def destroying_initial_function?
        destroying? && version == 1
      end
    end
  end
end
