module Scenic
  # Raised when a view definition in the database is different
  # from the definition used to create the migrations.
  class StoredDefinitionError < StandardError
    # Returns a new instance of StoredDefinitionError.
    #
    # @param definition [Scenic::Definition] definition used in migration
    # @param database_sql [String] definition in database
    def initialize(definition, database_sql)
      message = <<~TEXT
        View definition in #{definition.path}
        is different from database:
        #{database_sql}
      TEXT
      super(message)
    end
  end
end
