require "scenic/command_recorder/statement_arguments"

module Scenic
  # @api private
  module CommandRecorder
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
      drop_view_args = StatementArguments.new(args).remove_version.to_a
      [:drop_view, drop_view_args]
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
