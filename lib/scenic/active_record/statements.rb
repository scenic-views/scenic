require "rails"

module Scenic
  module ActiveRecord
    module Statements
      def create_view(name, version_or_definition = 1)
        if version_or_definition.is_a? String
          view_definition = version_or_definition
        else
          view_definition = definition(name, version_or_definition)
        end

        execute "CREATE VIEW #{name} AS #{view_definition};"
      end

      def drop_view(name, *_)
        execute "DROP VIEW #{name};"
      end

      def update_view(name, version)
        drop_view(name)
        create_view(name, version)
      end

      private

      def definition(name, version)
        File.read(::Rails.root.join("db", "views", "#{name}_v#{version}.sql"))
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Scenic::ActiveRecord::Statements
