module Scenic
  module Adapters
    class Postgres
      # Custom error classes for PostgreSQL specific errors
      #
      # These error classes are for more descriptive errors when users attempt
      # to use materialized view features not supported by their current
      # version.
      class MaterializedViewsNotSupportedError < StandardError
        def initialize
          super("Materialized views require Postgres 9.3 or newer")
        end
      end
      class ConcurrentRefreshesNotSupportedError < StandardError
        def initialize
          super("Concurrent materialized view refreshes require Postgres 9.4 or newer")
        end
      end
    end
  end
end
