module Scenic
  # Methods that are made available in migrations for managing Scenic views.
  module Statements
    # Create a new database view.
    #
    # @param name [String, Symbol] The name of the database view.
    # @param version [Fixnum] The version number of the view, used to find the
    #   definition file in `db/views`. This defaults to `1` if not provided.
    # @param sql_definition [String] The SQL query for the view schema. An error
    #   will be raised if `sql_definition` and `version` are both set,
    #   as they are mutually exclusive.
    # @param materialized [Boolean, Hash] Set to a truthy value to create a
    #   materialized view. Hash
    # @option materialized [Boolean] :no_data (false) Set to true to create
    #   materialized view without running the associated query. You will need
    #   to perform a non-concurrent refresh to populate with data.
    # @param database [Symbol] Override the database used for this operation.
    #   Defaults to detecting the database from the current ActiveRecord
    #   connection.
    # @return The database response from executing the create statement.
    #
    # @example Create from `db/views/searches_v02.sql`
    #   create_view(:searches, version: 2)
    #
    # @example Create from provided SQL string
    #   create_view(:active_users, sql_definition: <<-SQL)
    #     SELECT * FROM users WHERE users.active = 't'
    #   SQL
    #
    # @example Create view on secondary database
    #   create_view(:searches, version: 2, database: :secondary)
    #
    def create_view(
      name,
      version: nil,
      sql_definition: nil,
      materialized: false,
      database: nil
    )
      if version.present? && sql_definition.present?
        raise(
          ArgumentError,
          "sql_definition and version cannot both be set"
        )
      end

      if version.blank? && sql_definition.blank?
        version = 1
      end

      effective_database = database_for(database)
      sql_definition ||= definition(name, version, effective_database)
      adapter = adapter_for(database, effective_database)

      if materialized
        options = materialized_options(materialized)

        adapter.create_materialized_view(
          name,
          sql_definition,
          no_data: options[:no_data]
        )
      else
        adapter.create_view(name, sql_definition)
      end
    end

    # Drop a database view by name.
    #
    # @param name [String, Symbol] The name of the database view.
    # @param revert_to_version [Fixnum] Used to reverse the `drop_view` command
    #   on `rake db:rollback`. The provided version will be passed as the
    #   `version` argument to {#create_view}.
    # @param materialized [Boolean] Set to true if dropping a meterialized view.
    #   defaults to false.
    # @param database [Symbol] Override the database used for this operation.
    #   Defaults to detecting the database from the current ActiveRecord
    #   connection. Ignored here but recorded for rollbacks.
    # @return The database response from executing the drop statement.
    #
    # @example Drop a view, rolling back to version 3 on rollback
    #   drop_view(:users_who_recently_logged_in, revert_to_version: 3)
    #
    def drop_view(
      name,
      revert_to_version: nil, # rubocop:disable Lint/UnusedMethodArgument
      materialized: false,
      database: nil
    )
      effective_database = database_for(database)
      adapter = adapter_for(database, effective_database)
      if materialized
        adapter.drop_materialized_view(name)
      else
        adapter.drop_view(name)
      end
    end

    # Update a database view to a new version.
    #
    # The existing view is dropped and recreated using the supplied `version`
    # parameter.
    #
    # @param name [String, Symbol] The name of the database view.
    # @param version [Fixnum] The version number of the view.
    # @param sql_definition [String] The SQL query for the view schema. An error
    #   will be raised if `sql_definition` and `version` are both set,
    #   as they are mutually exclusive.
    # @param revert_to_version [Fixnum] The version number to rollback to on
    #   `rake db rollback`
    # @param materialized [Boolean, Hash] True or a Hash if updating a
    #   materialized view.
    # @option materialized [Boolean] :no_data (false) Set to true to update
    #   a materialized view without loading data. You will need to perform a
    #   refresh to populate with data. Cannot be combined with the :side_by_side
    #   option.
    # @option materialized [Boolean] :side_by_side (false) Set to true to update
    #   update a materialized view using our side-by-side strategy, which will
    #   limit the time the view is locked at the cost of increasing disk usage.
    #   The view is initially updated with a temporary name and atomically
    #   swapped once it is successfully created with data. Cannot be combined
    #   with the :no_data option.
    # @param database [Symbol] Override the database used for this operation.
    #   Defaults to detecting the database from the current ActiveRecord
    #   connection. Ignored here but recorded for rollbacks.
    # @return The database response from executing the create statement.
    #
    # @example
    #   update_view :engagement_reports, version: 3, revert_to_version: 2
    #   update_view :comments, version: 2, revert_to_version: 1, materialized: { side_by_side: true }
    def update_view(
      name,
      version: nil,
      sql_definition: nil,
      revert_to_version: nil, # rubocop:disable Lint/UnusedMethodArgument
      materialized: false,
      database: nil
    )
      if version.blank? && sql_definition.blank?
        raise(
          ArgumentError,
          "sql_definition or version must be specified"
        )
      end

      if version.present? && sql_definition.present?
        raise(
          ArgumentError,
          "sql_definition and version cannot both be set"
        )
      end

      effective_database = database_for(database)
      sql_definition ||= definition(name, version, effective_database)
      adapter = adapter_for(database, effective_database)

      if materialized
        options = materialized_options(materialized)

        if options[:no_data] && options[:side_by_side]
          raise(
            ArgumentError,
            "no_data and side_by_side options cannot be combined"
          )
        end

        if options[:side_by_side] && !transaction_open?
          raise "a transaction is required to perform a side-by-side update"
        end

        adapter.update_materialized_view(
          name,
          sql_definition,
          no_data: options[:no_data],
          side_by_side: options[:side_by_side]
        )
      else
        adapter.update_view(name, sql_definition)
      end
    end

    # Update a database view to a new version using `CREATE OR REPLACE VIEW`.
    #
    # The existing view is replaced using the supplied `version`
    # parameter.
    #
    # Does not work with materialized views due to lack of database support.
    #
    # @param name [String, Symbol] The name of the database view.
    # @param version [Fixnum] The version number of the view.
    # @param revert_to_version [Fixnum] The version number to rollback to on
    #   `rake db rollback`
    # @param database [Symbol] Override the database used for this operation.
    #   Defaults to detecting the database from the current ActiveRecord
    #   connection. Ignored here but recorded for rollbacks.
    # @return The database response from executing the create statement.
    #
    # @example
    #   replace_view :engagement_reports, version: 3, revert_to_version: 2
    #
    def replace_view(
      name,
      version: nil,
      revert_to_version: nil, # rubocop:disable Lint/UnusedMethodArgument
      materialized: false,
      database: nil
    )
      if version.blank?
        raise ArgumentError, "version is required"
      end

      if materialized
        raise ArgumentError, "Cannot replace materialized views"
      end

      effective_database = database_for(database)
      sql_definition = definition(name, version, effective_database)

      adapter_for(database, effective_database).replace_view(name, sql_definition)
    end

    private

    def database_for(explicit)
      if explicit
        explicit
      elsif respond_to?(:pool) && pool.respond_to?(:db_config)
        Scenic::DatabasePaths.database_for_config_name(pool.db_config.name)
      else
        :default
      end
    end

    def adapter_for(explicit_database, effective_database)
      registered = Scenic.configuration.databases.key?(effective_database)
      if explicit_database || registered
        Scenic.database(effective_database)
      else
        Scenic.adapter_for(connection_proxy)
      end
    end

    def connection_proxy
      Struct.new(:connection).new(self)
    end

    def definition(name, version, database = nil)
      Scenic::Definition.new(name, version, database: database).to_sql
    end

    def materialized_options(materialized)
      if materialized.is_a? Hash
        {
          no_data: materialized.fetch(:no_data, false),
          side_by_side: materialized.fetch(:side_by_side, false)
        }
      else
        {
          no_data: false,
          side_by_side: false
        }
      end
    end
  end
end
