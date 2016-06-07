module Scenic
  module Generators
    # @api private
    module CustomPathable
      extend ActiveSupport::Concern

      included do
        class_option :custom_path,
          type: :string,
          required: false,
          desc: 'Sets the path for the view',
          default: ''
      end

      private

      def custom_path
        options[:custom_path].to_s
      end

      def custom_path?
        custom_path.present?
      end
    end
  end
end
