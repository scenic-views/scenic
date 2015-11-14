module Scenic
  module Adapters
    # Abstract base class for Scenic database adapters.
    class Abstract
      # Returns an array of views in the datbase as [Scenic::View] objects.
      #
      # This collection of views is used by the [Scenic::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # This method has no default implementation and must be implemented by
      # all adapters.
      #
      # @return [Array<Scenic::View>]
      def views
        raise NotImplementedError
      end

      # Creates a view in the database.
      #
      # This method has a default implementation that should work for all
      # relational databases that support views.
      #
      # @param name The name of the view to create
      # @param sql_definition the SQL schema for the view.
      # @return [void]
      def create_view(name, sql_definition)
        execute "CREATE VIEW #{name} AS #{sql_definition};"
      end

      # Drops the named view from the database
      #
      # This method has a default implementation that should work for all
      # relational databases that support views.
      #
      # @param name The name of the view to drop
      # @return [void]
      def drop_view(name)
        execute "DROP VIEW #{name};"
      end

      # Creates a materialized view in the database
      #
      # This method has no default implementation and should be implemented by
      # adapters that support materialized views.
      #
      # @param name The name of the materialized view to create
      # @param sql_definition The SQL schema that defines the materialized view.
      # @return [void]
      def create_materialized_view(name, sql_definition)
        raise NotImplementedError
      end

      # Drops a materialized view in the database
      #
      # This method has no default implementation and should be implemented by
      # adapters that support materialized views.
      #
      # @param name The name of the materialized view to drop.
      # @return [void]
      def drop_materialized_view(name)
        raise NotImplementedError
      end

      # Refreshes a materialized view from its SQL schema.
      #
      # This method has no default implementation and should be implemented by
      # adapters that support materialized views.
      #
      # @param name The name of the materialized view to refresh..
      # @return [void]
      def refresh_materialized_view(name)
        raise NotImplementedError
      end

      private

      def execute(sql, base = ActiveRecord::Base)
        base.connection.execute sql
      end
    end
  end
end
