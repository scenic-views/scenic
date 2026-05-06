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
        class_option :database,
          type: :string,
          required: false,
          desc: "The database to use",
          default: nil
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

      def database
        options[:database] && validated_database
      end

      def validated_database
        @validated_database ||= begin
          name = options[:database].to_sym
          if name == :default || configured_database_names.include?(name)
            name
          else
            raise ArgumentError,
              "Unknown database :#{name}. Configured databases: " \
              "#{configured_database_names.inspect}"
          end
        end
      end

      def configured_database_names
        @configured_database_names ||= ActiveRecord::Base.configurations
          .configs_for(env_name: Rails.env)
          .map { |config| config.name.to_sym }
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
