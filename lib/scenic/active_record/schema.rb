require 'rails'

module Scenic
  module ActiveRecord
    module Schema
      module Statements
        def create_view(name, version)
          execute "CREATE VIEW #{name} AS #{schema(name, version)};"
        end

        def drop_view(name)
          execute "DROP VIEW #{name};"
        end

        private

        def schema(name, version)
          File.read(::Rails.root.join('db', 'views', "#{name}_v#{version}.sql"))
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Scenic::ActiveRecord::Schema::Statements
