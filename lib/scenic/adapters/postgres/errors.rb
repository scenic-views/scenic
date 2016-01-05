module Scenic
  module Adapters
    class Postgres
      # Raised when a materialized view operation is attempted on a database
      # version that does not support materialized views.
      #
      # Materialized views are supported on Postgres 9.3 or newer.
      class MaterializedViewsNotSupportedError < StandardError
        def initialize
          super("Materialized views require Postgres 9.3 or newer")
        end
      end

      # Raised when attempting a concurrent materialized view refresh on a
      # database version that does not support that.
      #
      # Concurrent materialized view refreshes are supported on Postgres 9.4 or
      # newer.
      class ConcurrentRefreshesNotSupportedError < StandardError
        def initialize
          super("Concurrent materialized view refreshes require Postgres 9.4 or newer")
        end
      end
    end
  end
end
