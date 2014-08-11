module Scenic
  module Statements
    # Public: Create a new database view.
    #
    # name - A string or symbol containing the singular name of the database
    #        view. Cannot conflict with any other view or table names.
    # version - The version number of the view. If present, will be used to find
    #           the definition file in db/views in the form db/views/[pluralized
    #           name]_v[2 digit zero padded version].sql.
    #           Example: db/views/searches_v02.sql.
    # sql_definition - A string containing the SQL definition of the view. If
    #                  both sql_definition and version are provided,
    #                  sql_definition takes prescedence.
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
    def create_view(name, version: 1, sql_definition: nil)
      if version.blank? && sql_definition.nil?
        raise(
          ArgumentError,
          "view_definition or version_number must be specified"
        )
      end

      sql_definition ||= definition(name, version)

      Scenic.database.create_view(name, sql_definition)
    end

    # Public: Drop a database view by name.
    #
    # name - A string or symbol containing the singular name of the database
    #        view. Must be an existing view.
    # revert_to_version - Used to revert the drop_view command in the
    #                     db:rollback rake task, which would pass the version
    #                     number to create_view. Usually the most recent
    #                     version.
    #
    # Example
    #
    #   drop_view(:users_who_recently_logged_in, 3)
    #
    # Returns the database response from executing the DROP VIEW statement.
    def drop_view(name, revert_to_version: nil)
      Scenic.database.drop_view(name)
    end

    # Public: Update a database view to a new version by first dropping the
    # previous version then creating the new version.
    #
    # name - A string or symbol containing the singular name of the database
    #        view. Must be an existing view.
    # version - The version number of the view. See create_view for details.
    # revert_to_version - The version to revert to for db:rollback. Usually the
    #                     previous version. See drop_view for details.
    #
    # Example
    #
    #   update_view(:engagement_reports, version: 3, revert_to_version: 2)
    #
    # Returns the database response from executing the CREATE VIEW statement.
    def update_view(name, version: nil, revert_to_version: nil)
      if version.blank?
        raise ArgumentError, "version is required"
      end

      drop_view(name, revert_to_version: revert_to_version)
      create_view(name, version: version)
    end

    private

    def definition(name, version)
      Scenic::Definition.new(name, version).to_sql
    end
  end
end
