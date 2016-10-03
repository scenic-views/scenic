module Scenic
  # The in-memory representation of a function definition.
  #
  # **This object is used internally by adapters and the schema dumper and is
  # not intended to be used by application code. It is documented here for
  # use by adapter gems.**
  #
  # @api extension
  class Function

    # The name of the function
    # @return [String]
    #
    # @example "hello_world"
    attr_reader :name

    # The SQL definition for the query that defines the view
    # @return [String]
    #
    # @example
    #   "CREATE OR REPLACE FUNCTION hello()
    #       RETURNS VARCHAR AS
    #    $$
    #    BEGIN
    #      RETURN 'hello';
    #    END
    #    $$ LANGUAGE plpgsql;"
    attr_reader :definition

    # The DB namespace or schema that the function belongs to
    # @return [String]
    #
    # @example "public"
    attr_reader :namespace

    # The arguments to the function
    # @return [String]
    #
    # @example 'name character varying, number_of_times integer DEFAULT 1'
    attr_reader :arguments

    # The result type that is returned from the function
    # @return [String]
    #
    # @example 'character varying'
    attr_reader :result_type


    # The main function source or body
    # @return [String]
    #
    # @example
    # 'DECLARE concat_string VARCHAR;
    #  BEGIN
    #   concat_string := concat('hello ', name);
    #  RETURN concat_string;
    #  END'
    attr_reader :source

    # Returns a new instance of Function.
    #
    # @param name [String] The name of the function.
    # @param definition [String] The code/definition of the function.
    def initialize(name:, definition: nil, namespace: nil, arguments: nil, result_type: nil, source: nil)
      @name = name
      @definition = definition
      @namespace = namespace
      @arguments = arguments
      @result_type = result_type
      @source = source
    end

    # @api private
    def ==(other)
      name == other.name &&
        definition == other.definition
    end

    # @api private
    def to_schema
      safe_to_symbolize_name = name.include?(".") ? "'#{name}'" : name

      <<-DEFINITION
  create_function :#{safe_to_symbolize_name}, sql_definition: <<-\SQL
    #{definition.indent(2)}
   SQL

      DEFINITION
    end

    def definition
      if @definition.nil?
        @definition = generate_definition_from_parts
      end
      @definition
    end

    private

    def generate_definition_from_parts
      <<-DEFINITION
CREATE OR REPLACE FUNCTION #{namespaced_name_if_required}(#{arguments})
RETURNS #{result_type}
LANGUAGE plpgsql
AS $function$
#{source}
$function$
      DEFINITION
    end

    def namespaced_name_if_required
      if Scenic.configuration.dump_function_namespace_in_schema
        "#{namespace}.#{name}"
      else
        name
      end
    end
  end
end
