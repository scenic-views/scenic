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

    # Options definition for security_invoker and security_barrier
    # @return Hash[Symbol, Boolean]
    attr_reader :options

    # Returns a new instance of View.
    #
    # @param name [String] The name of the view.
    # @param definition [String] The SQL for the query that defines the view.
    # @param materialized [Boolean] `true` if the view is materialized.
    def initialize(name:, definition:, materialized:, options:)
      @name = name
      @definition = definition
      @materialized = materialized
      @options = options
    end

    # @api private
    def ==(other)
      name == other.name &&
        definition == other.definition &&
        materialized == other.materialized &&
        options == other.options
    end

    # @api private
    def to_schema
      materialized_option = materialized ? "materialized: true, " : ""
      security_barrier_option = options[:security_barrier] ? "security_barrier: true, " : ""
      security_invoker_option = options[:security_invoker] ? "security_invoker: true, " : ""

      <<-DEFINITION
  create_view #{UnaffixedName.for(name).inspect}, #{security_barrier_option}#{security_invoker_option}#{materialized_option}sql_definition: <<-\SQL
    #{escaped_definition.indent(2)}
  SQL
      DEFINITION
    end

    def escaped_definition
      definition.gsub("\\", "\\\\\\")
    end
  end
end
