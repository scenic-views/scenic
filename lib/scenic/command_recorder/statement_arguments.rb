module Scenic
  module CommandRecorder
    # @api private
    class StatementArguments
      def initialize(args)
        @args = args.clone
        @options = @args.extract_options!
      end

      def view
        args[0]
      end

      def version
        options[:version]
      end

      def materialized?
        options[:materialized]
      end

      def revert_to_version
        options[:revert_to_version]
      end

      def invert_version
        StatementArguments.new([*args, options_for_revert])
      end

      def remove_version
        StatementArguments.new([*args, options_without_version])
      end

      def invert_names
        StatementArguments.new([*args.reverse, options])
      end

      def to_a
        args.to_a.dup.delete_if(&:empty?).tap do |array|
          array << options if options.present?
        end
      end

      private

      attr_reader :args, :options

      def options_for_revert
        options.clone.tap do |revert_options|
          revert_options.delete(:version)
          revert_options.delete(:revert_to_version)
          if revert_to_version.present?
            revert_options[:version] = revert_to_version
          end
          if version.present?
            revert_options[:revert_to_version] = version
          end
        end
      end

      def options_without_version
        options.except(:version)
      end
    end
  end
end
