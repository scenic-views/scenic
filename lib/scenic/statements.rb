require_relative "./errors"
require_relative "./definition"

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
    # @param materialized [Boolean, Hash] Default: false.
    #   Set to true to create a materialized view.
    #   Set to { no_data: true } to not populate the view.
    #   Set to { copy_indexes_from: "other_view_name" } to copy indexes from
    #     that view. Useful when used as a first step before `replace_view`.
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
    def create_view(name, version: nil, sql_definition: nil, materialized: false)
      if version.present? && sql_definition.present?
        raise(
          ArgumentError,
          "sql_definition and version cannot both be set",
        )
      end

      if version.blank? && sql_definition.blank?
        version = 1
      end

      sql_definition ||= definition(name, version).to_sql

      if materialized
        database.create_materialized_view(
          name,
          sql_definition,
          no_data: no_data(materialized),
          copy_indexes_from: copy_indexes_from(materialized),
        )
      else
        database.create_view(name, sql_definition)
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
    def drop_view(name, revert_to_version: nil, materialized: false)
      if materialized
        database.drop_materialized_view(name)
      else
        database.drop_view(name)
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
    # @param materialized [Boolean, Hash] True if updating a materialized view.
    #   Set to { no_data: true } to update materialized view without loading
    #   data. Defaults to false.
    # @return The database response from executing the create statement.
    #
    # @example
    #   update_view :engagement_reports, version: 3, revert_to_version: 2
    #
    def update_view(name, version: nil, sql_definition: nil, revert_to_version: nil, materialized: false)
      if version.blank? && sql_definition.blank?
        raise(
          ArgumentError,
          "sql_definition or version must be specified",
        )
      end

      if version.present? && sql_definition.present?
        raise(
          ArgumentError,
          "sql_definition and version cannot both be set",
        )
      end

      sql_definition ||= definition(name, version).to_sql

      if materialized
        database.update_materialized_view(
          name,
          sql_definition,
          no_data: no_data(materialized),
        )
      else
        database.update_view(name, sql_definition)
      end
    end

    # Update a database view to a new version using `CREATE OR REPLACE VIEW`.
    #
    # The existing view is replaced using the supplied `version`
    # parameter.
    #
    # Does not work with materialized views due to lack of database support.
    #
    # @param from_name [String, Symbol] The name of the database view.
    # @param to_name [String, Symbol] The next name of the database
    #   materialized view.
    # @param version [Fixnum] The version number of the view.
    # @param revert_to_version [Fixnum] The version number to rollback to on
    #   `rake db rollback`
    # @param materialized [Boolean] True if updating a materialized view.
    # @return The database response from executing the create statement.
    #
    # @example
    #   replace_view :engagement_reports, version: 3, revert_to_version: 2
    #
    def replace_view(
      from_name, to_name = nil,
      version: nil, revert_to_version: nil, materialized: false
    )
      if version.blank?
        raise ArgumentError, "version is required"
      end

      if materialized
        if to_name.blank?
          raise ArgumentError, "to_name is required for materialized view"
        end
        result = database.replace_materialized_view(from_name, to_name)
        raise_unless_similar_definition(to_name, version)
        result
      else
        sql_definition = definition(from_name, version).to_sql
        database.replace_view(from_name, sql_definition)
      end
    end

    # Rename a database view by name.
    #
    # @param from_name [String, Symbol] The previous name of the database view.
    # @param to_name [String, Symbol] The next name of the database view.
    # @param version [Fixnum] The version number of the view `to_name`.
    # @param revert_to_version [Fixnum] The version number
    #   of the view `from_name` to rollback to on `rake db rollback`
    # @param materialized [Boolean, Hash] True if updating a materialized view.
    #   Set to { rename_indexes: true } to rename materialized view indexes
    #   by substituing in their name the previous view name
    #   to the next view name. Defaults to false.
    # @return The database response from executing the rename statement.
    #
    # @example Rename a view
    #   drop_view(:engggggement_reports, :engagement_reports)
    #
    def rename_view(
      from_name, to_name,
      version: nil, revert_to_version: nil, materialized: false
    )
      if version.blank?
        raise ArgumentError, "version is required"
      end

      result = if materialized
                 database.rename_materialized_view(
                   from_name,
                   to_name,
                   rename_indexes: rename_indexes(materialized),
                 )
               else
                 database.rename_view(from_name, to_name)
               end

      raise_unless_similar_definition(to_name, version)

      result
    end

    private

    delegate :database, to: :Scenic

    def definition(name, version)
      Scenic::Definition.new(name, version)
    end

    def no_data(materialized)
      if materialized.is_a?(Hash)
        materialized.fetch(:no_data, false)
      else
        false
      end
    end

    def copy_indexes_from(materialized)
      if materialized.is_a?(Hash)
        materialized.fetch(:copy_indexes_from, false)
      else
        false
      end
    end

    def rename_indexes(materialized)
      if materialized.is_a?(Hash)
        materialized.fetch(:rename_indexes, false)
      else
        false
      end
    end

    def raise_unless_similar_definition(name, version)
      view_definition = definition(name, version)
      unless database.view_with_similar_definition?(view_definition)
        database_sql = database.normalize_view_sql(name)
        raise StoredDefinitionError.new(view_definition, database_sql)
      end
    end
  end
end
