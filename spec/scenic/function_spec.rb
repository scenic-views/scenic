require 'spec_helper'

module Scenic

  describe Function do

    describe '#definition' do

      let(:function) { Function.new(args) }
      let(:function_definition) { function.definition }

      context 'when a full definition is passed during initialization' do

        let(:args) { { name: 'hello_world', definition: :definition.to_s } }

        it 'returns with an unprocessed definition' do
          expect(function_definition).to eq(:definition.to_s)
        end
      end

      context 'when individual parts of a function are provided (during schema dump)' do

        let(:name) { 'hello' }
        let(:namespace) { 'public' }
        let(:arguments) { 'name character varying, number_of_times integer DEFAULT 1' }
        let(:result_type) { 'character varying' }

        let(:source) do
          <<-DEFINITION
            DECLARE concat_string VARCHAR;
            BEGIN
              concat_string := concat('hello ', name);
              RETURN concat_string;
            END
          DEFINITION
        end

        let(:args) { { name: name, namespace: namespace, arguments: arguments, result_type: result_type, source: source } }

        before(:each) do
          Scenic.configure do |config|
            config.dump_function_namespace_in_schema = dump_function_namespace_in_schema
          end
        end

        context 'Configuration.dump_function_namespace_in_schema value is false (default)' do

          let(:dump_function_namespace_in_schema) { false }

          it 'generates a function definition without the namespace' do
            expect(function_definition).to eq(<<-DEFINITION)
CREATE OR REPLACE FUNCTION #{name}(#{arguments})
RETURNS #{result_type}
LANGUAGE plpgsql
AS $function$
#{source}
$function$
            DEFINITION
          end
        end

        context 'Configuration.dump_function_namespace_in_schema value is true' do

          let(:dump_function_namespace_in_schema) { true }

          it 'generates a function definition with the namespace included' do
            expect(function_definition).to eq(<<-DEFINITION)
CREATE OR REPLACE FUNCTION #{namespace}.#{name}(#{arguments})
RETURNS #{result_type}
LANGUAGE plpgsql
AS $function$
#{source}
$function$
            DEFINITION
          end
        end
      end
    end
  end
end
