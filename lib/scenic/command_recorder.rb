require "scenic/command_recorder/statement_arguments"

module Scenic
  # @api private
  module CommandRecorder
    METHODS = %i[
      create_view drop_view update_view replace_view rename_view
    ].freeze
    METHODS.each do |method|
      define_method(method) { |*args| record(method, args) }
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

    def invert_rename_view(args)
      perform_scenic_inversion(
        :rename_view,
        StatementArguments.new(args).invert_names.to_a,
      )
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
