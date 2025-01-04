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

      # Raised when attempting an operation that Scenic requires a transaction
      # to perform.
      #
      # Rails will execute all migrations in a transaction unless the migration
      # calls `disable_ddl_transaction!`. If you get this error, you can either
      # removed that line from your migration or explicitly wrap the operation
      # in question in a transaction.
      class TransactionRequiredError < StandardError
      end
    end
  end
end
