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
          default: false,
          aliases: ["--no-data"]
        class_option :side_by_side,
          type: :boolean,
          required: false,
          desc: "Uses side-by-side strategy to update materialized view",
          default: false,
          aliases: ["--side-by-side"]
        class_option :replace,
          type: :boolean,
          required: false,
          desc: "Uses replace_view instead of update_view",
          default: false
      end

      private

      def materialized?
        options[:materialized]
      end

      def replace_view?
        options[:replace]
      end

      def no_data?
        options[:no_data]
      end

      def side_by_side?
        options[:side_by_side]
      end

      def materialized_view_update_options
        set_options = {no_data: no_data?, side_by_side: side_by_side?}
          .select { |_, v| v }

        if set_options.empty?
          "true"
        else
          string_options = set_options.reduce("") do |memo, (key, value)|
            memo + "#{key}: #{value}, "
          end

          "{ #{string_options.chomp(", ")} }"
        end
      end
    end
  end
end
