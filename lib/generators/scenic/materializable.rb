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
        class_option :materialized_no_data,
          type: :boolean,
          required: false,
          desc: "Makes the view materialized with NO DATA",
          default: false
      end

      private

      def materialized?
        options[:materialized] || options[:materialized_no_data]
      end

      def materialized_no_data?
        options[:materialized_no_data]
      end
    end
  end
end
