module Scenic
  module ActiveRecord
    module CommandRecorder
      def create_view(*args)
        record(:create_view, args)
      end

      def drop_view(*args)
        record(:drop_view, args)
      end

      def invert_create_view(args)
        [:drop_view, args]
      end

      def invert_drop_view(args)
        scenic_args = ScenicArguments.new(args)

        if scenic_args.revert_to_version.nil?
          raise_irriversible(:drop_view)
        end

        [:create_view, scenic_args.view]
      end

      private

      def raise_irriversible(method)
        message = "#{method} is reversible only if given a revert_to_version"
        raise ::ActiveRecord::IrreversibleMigration, message
      end

      class ScenicArguments
        def initialize(args)
          @args = args
        end

        def view
          @args[0]
        end

        def options
          @options ||= @args[1] || {}
        end

        def revert_to_version
          options[:revert_to_version]
        end
      end
    end
  end
end
