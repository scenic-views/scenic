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
      @dumpable_views_in_database ||= scenic_views_for_connection.reject do |view|
        ignored?(view.name)
      end
    end

    def scenic_views_for_connection
      Scenic::Adapters::Postgres::Views.new(@connection).all
    end
  end
end
