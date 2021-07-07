module Scenic
  module CommandRecorder
    # @api private
    class StatementArguments
      def initialize(args)
        @args = args.freeze
      end

      def view
        @args[0]
      end

      def version
        options[:version]
      end

      def revert_to_version
        options[:revert_to_version]
      end

      def invert_version
        StatementArguments.new([view, options_for_revert])
      end

      def remove_version
        StatementArguments.new([view, options_without_version])
      end

      def to_a
        @args.to_a.dup.delete_if(&:empty?)
      end

      private

      def options
        @options ||= @args[1] || {}
      end

      if Hash.respond_to? :ruby2_keywords_hash
        def keyword_hash(hash)
          Hash.ruby2_keywords_hash hash
        end
      else
        def keyword_hash(hash)
          hash
        end
      end

      def options_for_revert
        opts = options.clone.tap do |revert_options|
          revert_options[:version] = revert_to_version
          revert_options.delete(:revert_to_version)
        end
        keyword_hash opts
      end

      def options_without_version
        keyword_hash options.except(:version)
      end
    end
  end
end
