module Scenic
  # Methods that are made available in migrations for managing Scenic views.
  module Statements
    # Create a new database view.
    #
    # @param name [String, Symbol] The name of the database view.
    # @param version [Fixnum] The version number of the view, used to find the
    #   definition file in `db/views`. This defaults to `1` if not provided.
    # @param sql_definition [String] The SQL query for the view schema. If both
    #   `sql_defintiion` and `version` are provided, `sql_definition` takes
    #   prescedence.
    # @param materialized [Boolean] Set to true to create a materialized view.
    #   Defaults to false.
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
    def create_view(name, version: 1, sql_definition: nil, materialized: false)
      if version.blank? && sql_definition.nil?
        raise(
          ArgumentError,
          "view_definition or version_number must be specified"
        )
      end

      sql_definition ||= definition(name, version)

      if materialized
        Scenic.database.create_materialized_view(name, sql_definition)
      else
        Scenic.database.create_view(name, sql_definition)
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
    # @return The database response from executing the drop statement.
    #
    # @example Drop a view, rolling back to version 3 on rollback
    #   drop_view(:users_who_recently_logged_in, revert_to_version: 3)
    #
    def drop_view(name, revert_to_version: nil, materialized: false, sql_definition: nil)
      if materialized
        Scenic.database.drop_materialized_view(name)
      else
        Scenic.database.drop_view(name)
      end
    end

    # Update a database view to a new version.
    #
    # The existing view is dropped and recreated using the supplied `version`
    # parameter.
    #
    # @param name [String, Symbol] The name of the database view.
    # @param version [Fixnum] The version number of the view.
    # @param revert_to_version [Fixnum] The version number to rollback to on
    #   `rake db rollback`
    # @param materialized [Boolean] Must be false. Updating a meterialized view
    #   causes indexes on it to be dropped. For this reason you should
    #   explicitly use {#drop_view} followed by {#create_view} and recreate
    #   applicable indexes. Setting this to `true` will raise an error.
    # @return The database response from executing the create statement.
    #
    # @example
    #   update_view :engagement_reports, version: 3, revert_to_version: 2
    #
    def update_view(name, version: nil, revert_to_version: nil, materialized: false)
      if version.blank?
        raise ArgumentError, "version is required"
      end

      if materialized
        raise ArgumentError, "Updating materialized views is not supported "\
          "because it would cause any indexes to be dropped. Please use "\
          "'drop_view' followed by 'create_view', being sure to also recreate "\
          "any previously-existing indexes."
      end

      drop_view name,
        revert_to_version: revert_to_version,
        materialized: materialized
      create_view(name, version: version, materialized: materialized)
    end

    private

    def definition(name, version)
      Scenic::Definition.new(name, version).to_sql
    end
  end
end
