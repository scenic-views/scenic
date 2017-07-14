module Scenic
  module Generators
    # @api private
    module Materializable
      extend ActiveSupport::Concern

      included do
        class_option :materialized,
          type: :boolean,
          required: false,
          desc: "Makes the view materialized",
          default: false
        class_option :no_data,
          type: :boolean,
          required: false,
          desc: "Adds WITH NO DATA when materialized view creates/updates",
          default: false
      end

      private

      def materialized?
        options[:materialized]
      end

      def no_data?
        options[:no_data]
      end
    end
  end
end
