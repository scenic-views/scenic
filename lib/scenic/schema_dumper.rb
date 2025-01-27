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
  end
end
