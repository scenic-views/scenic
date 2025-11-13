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

    # Options hash for view WITH clause options
    # @return [Hash{Symbol => Object}]
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

      with_option = if options.present? && options.any?
        with_hash = options.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
        "with: { #{with_hash} }, "
      else
        ""
      end

      <<-DEFINITION
  create_view #{UnaffixedName.for(name).inspect}, #{with_option}#{materialized_option}sql_definition: <<-\SQL
    #{escaped_definition.indent(2)}
  SQL
      DEFINITION
    end

    def escaped_definition
      definition.gsub("\\", "\\\\\\")
    end
  end
end
