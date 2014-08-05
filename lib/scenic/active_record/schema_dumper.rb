require "rails"

module Scenic
  module ActiveRecord
    module SchemaDumper
      extend ActiveSupport::Concern

      included { alias_method_chain :tables, :views }

      def tables_with_views(stream)
        tables_without_views(stream)
        views(stream)
      end

      def views(stream)
        defined_views.sort.each do |view_name|
          next if ["schema_migrations", ignore_tables].flatten.any? do |ignored|
            case ignored
            when String; remove_prefix_and_suffix(view_name) == ignored
            when Regexp; remove_prefix_and_suffix(view_name) =~ ignored
            else
              raise StandardError, "ActiveRecord::SchemaDumper.ignore_tables accepts an array of String and / or Regexp values."
            end
          end
          view(view_name, stream)
        end
      end

      def view(name, stream)
        stream.puts(<<-DEFINITION)
  create_view :#{name}, sql_definition:<<-\SQL
#{views_with_definitions[name]}
  SQL
        DEFINITION
        stream
      end

      def defined_views
        views_with_definitions.keys
      end

      def views_with_definitions
        @views_with_definitions ||= begin
          query = Scenic.database.views_with_definitions_query
          Hash[@connection.execute(query, "SCHEMA").values]
        end
      end
    end
  end
end
