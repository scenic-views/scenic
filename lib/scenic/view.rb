module Scenic
  # The in-memory representation of a view definition.
  #
  # **This object is used internally by adapters and the schema dumper and is
  # not intended to be used by application code. It is documented here for
  # use by adapter gems.**
  #
  # @api extension
  class View
    # The name of the view
    # @return [String]
    attr_reader :name

    # The SQL schema for the query that defines the view
    # @return [String]
    #
    # @example
    #   "SELECT name, email FROM users UNION SELECT name, email FROM contacts"
    attr_reader :definition

    # True if the view is materialized
    # @return [Boolean]
    attr_reader :materialized

    # True if the view is materialized with NO DATA
    # @return [Boolean]
    attr_reader :no_data

    # Returns a new instance of View.
    #
    # @param name [String] The name of the view.
    # @param definition [String] The SQL for the query that defines the view.
    # @param materialized [String] `true` if the view is materialized.
    def initialize(name:, definition:, materialized:, no_data: false)
      @name = name
      @definition = definition
      @materialized = materialized
      @no_data = no_data
    end

    # @api private
    def ==(other)
      name == other.name &&
        definition == other.definition &&
        materialized == other.materialized
    end

    # @api private
    def to_schema
      materialized_option = materialized ? "materialized: true, " : ""
      no_data_option = no_data ? ", no_data: true" : ""

      <<-DEFINITION
  create_view #{name.inspect}, #{materialized_option} sql_definition: <<-\SQL
    #{definition.indent(2)}
  SQL
  #{no_data_option}
      DEFINITION
    end
  end
end
