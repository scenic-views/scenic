require "rails/generators"
require "rails/generators/rails/model/model_generator"
require "generators/scenic/view/view_generator"
require "generators/scenic/materializable"

module Scenic
  module Generators
    # @api private
    class ModelGenerator < Rails::Generators::NamedBase
      include Scenic::Generators::Materializable
      source_root File.expand_path("../templates", __FILE__)

      def invoke_rails_model_generator
        invoke "model",
          [file_path.singularize],
          options.merge(
            fixture_replacement: false,
            migration: false,
          )
      end

      def inject_model_methods
        if materialized? && generating?
          inject_into_class "app/models/#{file_path.singularize}.rb", class_name do
            evaluate_template("model.erb")
          end
        end
      end

      def invoke_view_generator
        invoke "scenic:view", [table_name], options
      end

      private

      def evaluate_template(source)
        source  = File.expand_path(find_in_source_paths(source.to_s))
        context = instance_eval("binding")
        ERB.new(
          ::File.binread(source),
          nil,
          "-",
          "@output_buffer",
        ).result(context)
      end

      def generating?
        behavior != :revoke
      end
    end
  end
end
