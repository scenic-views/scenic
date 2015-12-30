module Scenic
  module Adapters
    class Postgres
      # Decorates an ActiveRecord connection with methods that help determine
      # the connections capabilities.
      #
      # Every attempt is made to use the versions of these methods defined by
      # Rails where they are available and public before falling back to our own
      # implementations for older Rails versions.
      #
      # @api private
      class Connection < SimpleDelegator
        # True if the connection supports materialized views.
        #
        # Delegates to the method of the same name if it is already defined on
        # the connection. This is the case for Rails 4.2 or higher.
        #
        # @return [Boolean]
        def supports_materialized_views?
          if undecorated_connection.respond_to?(:supports_materialized_views?)
            super
          else
            postgresql_version >= 90300
          end
        end

        # True if the connection supports concurrent refreshes of materialized
        # views.
        #
        # @return [Boolean]
        def supports_concurrent_refreshes?
          postgresql_version >= 90400
        end

        # An integer representing the version of Postgres we're connected to.
        #
        # postgresql_version is public in Rails 5, but protected in earlier
        # versions.
        #
        # @return [Integer]
        def postgresql_version
          if undecorated_connection.respond_to?(:postgresql_version)
            super
          else
            undecorated_connection.send(:postgresql_version)
          end
        end

        private

        def undecorated_connection
          __getobj__
        end
      end
    end
  end
end
