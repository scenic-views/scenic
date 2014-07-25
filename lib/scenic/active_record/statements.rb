require "active_record"

module Scenic
  module ActiveRecord
    module Statements
      def create_view(name, version = 1)
        execute "CREATE VIEW #{name} AS #{schema(name, version)};"
      end

      def drop_view(name, *_)
        execute "DROP VIEW #{name};"
      end

      def update_view(name, version)
        drop_view(name)
        create_view(name, version)
      end

      private

      def schema(name, version)
        File.read(::Rails.root.join("db", "views", "#{name}_v#{version}.sql"))
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Scenic::ActiveRecord::Statements
