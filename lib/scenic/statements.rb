module Scenic
  module Statements
    def create_view(name, version: 1, sql_definition: nil)
      if version.nil? && sql_definition.nil?
        raise(
          ArgumentError,
          "view_definition or version_number must be specified"
        )
      end

      sql_definition ||= definition(name, version)

      execute Scenic.database.create_view(name, sql_definition)
    end

    def drop_view(name, revert_to_version: nil)
      execute Scenic.database.drop_view(name)
    end

    def update_view(name, version: nil, revert_to_version: nil)
      if version.nil?
        raise ArgumentError, "version is required"
      end

      drop_view(name)
      create_view(name, version: version)
    end

    private

    def definition(name, version)
      File.read(::Rails.root.join("db", "views", "#{name}_v#{version}.sql"))
    end
  end
end
