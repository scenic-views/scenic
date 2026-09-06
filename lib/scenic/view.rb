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

    # The default values defined on the view's columns, keyed by column name.
    #
    # A view column can carry a DEFAULT, which is what lets an updatable view be
    # inserted into without naming every column. The database stores it on the
    # view rather than in the view's query, so `CREATE VIEW` cannot express it
    # and it has to be dumped separately from the definition.
    #
    # @return [Hash<String, String>] column name => default expression
    #
    # @example
    #   { "status" => "'pending'::text" }
    attr_reader :column_defaults

    # Returns a new instance of View.
    #
    # @param name [String] The name of the view.
    # @param definition [String] The SQL for the query that defines the view.
    # @param materialized [Boolean] `true` if the view is materialized.
    # @param column_defaults [Hash<String, String>] The default values defined
    #   on the view's columns, as column name => default expression.
    def initialize(name:, definition:, materialized:, column_defaults: {})
      @name = name
      @definition = definition
      @materialized = materialized
      @column_defaults = column_defaults
    end

    # @api private
    def ==(other)
      name == other.name &&
        definition == other.definition &&
        materialized == other.materialized &&
        column_defaults == other.column_defaults
    end

    # @api private
    def to_schema
      materialized_option = materialized ? "materialized: true, " : ""
      column_defaults_option = if column_defaults.any?
        "column_defaults: #{column_defaults.inspect}, "
      else
        ""
      end

      <<-DEFINITION
  create_view #{UnaffixedName.for(name).inspect}, #{materialized_option}#{column_defaults_option}sql_definition: <<-\SQL
    #{escaped_definition.indent(2)}
  SQL
      DEFINITION
    end

    def escaped_definition
      definition.gsub("\\", "\\\\\\")
    end
  end
end
