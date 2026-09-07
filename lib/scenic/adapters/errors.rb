module Scenic
  module Adapters
    # Raised when view column defaults are used with an adapter that does not
    # support them. An adapter should return true from
    # `supports_column_defaults?` when supported.
    class ColumnDefaultsNotSupportedError < StandardError
      def initialize(adapter = Scenic.database)
        super("#{adapter.class} does not support view column defaults")
      end
    end
  end
end
