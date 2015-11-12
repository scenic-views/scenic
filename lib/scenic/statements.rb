module Scenic
  module Statements
    # Public: Create a new database view.
    #
    # name - A string or symbol containing the singular name of the database
    #        view. Cannot conflict with any other view or table names.
    # version - The version number of the view. If present, will be used to find
    #           the definition file in db/views in the form
    #           db/views/[pluralized name]_v[2 digit zero padded version].sql.
    #           Example: db/views/searches_v02.sql.
    # sql_definition - A string containing the SQL definition of the view. If
    #                  both sql_definition and version are provided,
    #                  sql_definition takes prescedence.
    # materialized - Boolean whether the view should be materialized.
    #                http://www.postgresql.org/docs/9.3/static/sql-creatematerializedview.html
    #
    # Examples
    #
    #   create_view(:searches, version: 2)
    #
    #   create_view(:active_users, sql_definition: <<-SQL)
    #     SELECT * FROM users WHERE users.active = 't'
    #   SQL
    #
    # Returns the database response from executing the CREATE VIEW statement.
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

    # Public: Drop a database view by name.
    #
    # name - A string or symbol containing the singular name of the database
    #        view. Must be an existing view.
    # revert_to_version - Used to revert the drop_view command in the
    #                     db:rollback rake task, which would pass the version
    #                     number to create_view. Usually the most recent
    #                     version.
    # materialized - Boolean whether the view should be materialized. See
    #                create_view for details.
    #
    # Example
    #
    #   drop_view(:users_who_recently_logged_in, 3)
    #
    # Returns the database response from executing the DROP VIEW statement.
    def drop_view(name, revert_to_version: nil, materialized: false)
      if materialized
        Scenic.database.drop_materialized_view(name)
      else
        Scenic.database.drop_view(name)
      end
    end

    # Public: Update a database view to a new version by first dropping the
    # previous version then creating the new version.
    #
    # name - A string or symbol containing the singular name of the database
    #        view. Must be an existing view.
    # version - The version number of the view. See create_view for details.
    # revert_to_version - The version to revert to for db:rollback. Usually the
    #                     previous version. See drop_view for details.
    # materialized - Should default to false. Updating a materialized view would
    #                cause indexes to be dropped. For this reason you should
    #                explicitly use `drop_view` followed by `create_view` and
    #                recreate applicable indexes. Setting this to `true` will
    #                raise an error.
    #
    # Example
    #
    #   update_view(:engagement_reports, version: 3, revert_to_version: 2)
    #
    #   update_view :users_with_disabilities,
    #     version: 12,
    #     revert_to_version: 11
    #
    # Returns the database response from executing the CREATE VIEW statement.
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
