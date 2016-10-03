require "scenic/command_recorder/statement_arguments"

module Scenic
  # @api private
  module CommandRecorder
    module FunctionCommands

      def create_function(*args)
        record(:create_function, args)
      end

      def drop_function(*args)
        record(:drop_function, args)
      end

      def update_function(*args)
        record(:update_function, args)
      end

      def invert_create_function(args)
        [:drop_function, args]
      end

      def invert_drop_function(args)
        perform_scenic_inversion(:create_function, args)
      end

      def invert_update_function(args)
        perform_scenic_inversion(:update_function, args)
      end
    end
  end
end
