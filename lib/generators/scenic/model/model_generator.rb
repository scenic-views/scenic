require "rails/generators"
require "rails/generators/rails/model/model_generator"
require "generators/scenic/view/view_generator"

module Scenic
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      def invoke_rails_model_generator
        invoke "model", [name], options.merge(migration: false)
      end

      def invoke_view_generator
        invoke "scenic:view", [table_name], options
      end
    end
  end
end
