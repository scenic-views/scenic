module Scenic
  module ActiveRecord
    module Statements
      def create_view(name, version: 1)
        execute "CREATE VIEW #{name} AS #{schema(name, version)};"
      end

      def drop_view(name)
        execute "DROP VIEW #{name};"
      end

      def update_view(name, version: nil)
        if version.nil?
          raise ArgumentError, 'version is required'
        end

        drop_view(name)
        create_view(name, version: version)
      end

      private

      def schema(name, version)
        File.read(::Rails.root.join("db", "views", "#{name}_v#{version}.sql"))
      end
    end
  end
end
