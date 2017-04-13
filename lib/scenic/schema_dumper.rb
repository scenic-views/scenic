require "rails"

module Scenic
  # @api private
  module SchemaDumper
    def tables(stream)
      super
      views(stream)
    end

    def views(stream)
      if dumpable_views_in_database.any?
        stream.puts
      end

      dumpable_views_in_database.each do |view|
        stream.puts(view.to_schema)
        indexes(view.name, stream)
      end
    end

    private

    def dumpable_views_in_database
      @dumpable_views_in_database ||= Scenic.database.views.reject do |view|
        ignored?(view.name)
      end
    end

    unless ActiveRecord::SchemaDumper.private_instance_methods(false).include?(:ignored?)
      # This method will be present in Rails 4.2.0 and can be removed then.
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
end
