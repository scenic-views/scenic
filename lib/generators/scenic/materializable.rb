module Scenic
  module Generators
    module Materializable
      extend ActiveSupport::Concern

      included do
        class_option :materialized,
          type: :boolean,
          required: false,
          desc: "Makes the view materialized",
          default: false
      end

      private

      def materialized?
        options[:materialized]
      end
    end
  end
end
