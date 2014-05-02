require 'rails'

module Scenic
  module ActiveRecord
    module Schema
      module Statements
        def create_view(name)
          execute "CREATE VIEW #{name} AS #{schema(name)};"
        end

        private

        def schema(name)
          File.read(::Rails.root.join('db', 'views', "#{name}.sql"))
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Scenic::ActiveRecord::Schema::Statements
