require "rails"

module Scenic
  module SchemaDumper
    extend ActiveSupport::Concern

    included { alias_method_chain :tables, :views }

    def tables_with_views(stream)
      tables_without_views(stream)
      views(stream)
    end

    def views(stream)
      views_in_database.select { |view| !ignored?(view.name) }.each do |view|
        stream.puts(view.to_schema)
      end
    end

    def views_in_database
      @views_in_database ||= Scenic.database.views.sort
    end

    private

    # This method will be present in Rails 4.1.5 or 5.0.0 and can be removed
    # then.
    def ignored?(table_name)
      ["schema_migrations", ignore_tables].flatten.any? do |ignored|
        case ignored
        when String; remove_prefix_and_suffix(table_name) == ignored
        when Regexp; remove_prefix_and_suffix(table_name) =~ ignored
        else
          raise StandardError, "ActiveRecord::SchemaDumper.ignore_tables accepts an array of String and / or Regexp values."
        end
      end
    end
  end
end
