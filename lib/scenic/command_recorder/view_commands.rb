require "scenic/command_recorder/statement_arguments"

module Scenic
  # @api private
  module CommandRecorder
    module ViewCommands

      def create_view(*args)
        record(:create_view, args)
      end

      def drop_view(*args)
        record(:drop_view, args)
      end

      def update_view(*args)
        record(:update_view, args)
      end

      def replace_view(*args)
        record(:replace_view, args)
      end

      def invert_create_view(args)
        [:drop_view, args]
      end

      def invert_drop_view(args)
        perform_scenic_inversion(:create_view, args)
      end

      def invert_update_view(args)
        perform_scenic_inversion(:update_view, args)
      end

      def invert_replace_view(args)
        perform_scenic_inversion(:replace_view, args)
      end

    end
  end
end
