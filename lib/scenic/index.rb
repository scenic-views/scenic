module Scenic
  # The in-memory representation of a database index.
  #
  # **This object is used internally by adapters and the schema dumper and is
  # not intended to be used by application code. It is documented here for
  # use by adapter gems.**
  #
  # @api extension
  class Index
    # The name of the object that has the index
    # @return [String]
    attr_reader :object_name

    # The name of the index
    # @return [String]
    attr_reader :index_name

    # The SQL statement that defines the index
    # @return [String]
    #
    # @example
    #   "CREATE INDEX index_users_on_email ON users USING btree (email)"
    attr_reader :definition

    # The schema under which the index is defined
    # @return [String]
    attr_reader :schema_name

    # Returns a new instance of Index
    #
    # @param object_name [String] The name of the object that has the index
    # @param index_name [String] The name of the index
    # @param definition [String] The SQL statements that defined the index
    def initialize(object_name:, index_name:, definition:, schema_name:)
      @object_name = object_name
      @index_name = index_name
      @definition = definition
      @schema_name = schema_name
    end

    # Return a new instance of Index with the definition changed to create
    # the index against a different object name.
    #
    # @param object_name [String] The name of the object that has the index
    def with_other_object_name(object_name)
      type = if @definition.start_with? "CREATE UNIQUE"
               "CREATE UNIQUE INDEX"
             else
               "CREATE INDEX"
             end
      old_prefix = "#{type} #{@index_name} ON #{@schema_name}.#{@object_name}"
      new_prefix = "#{type} #{@index_name} ON #{@schema_name}.#{object_name}"
      unless @definition.start_with? old_prefix
        raise "Unhandled index definition: '#{@definition}' (expected to start with '#{old_prefix}'"
      end
      tweaked_definition = new_prefix + @definition.slice((old_prefix.size)..(@definition.size))
      self.class.new(
        object_name: object_name,
        index_name: @index_name,
        schema_name: @schema_name,
        definition: tweaked_definition
      )
    end
  end
end
