require 'scenic/command_recorder/statement_arguments'
require 'scenic/command_recorder/view_commands'
require 'scenic/command_recorder/function_commands'

module Scenic
  # @api private
  module CommandRecorder
    include ViewCommands
    include FunctionCommands

    private

    def perform_scenic_inversion(method, args)
      scenic_args = StatementArguments.new(args)

      if scenic_args.revert_to_version.nil?
        message = "#{method} is reversible only if given a revert_to_version"
        raise ActiveRecord::IrreversibleMigration, message
      end

      [method, scenic_args.invert_version.to_a]
    end
  end
end
