require 'spec_helper'

module Scenic
  module Statements
    describe Scenic::Statements::FunctionStatements do
      before do
        adapter = instance_double('Scenic::Adapaters::Postgres').as_null_object
        allow(Scenic).to receive(:database).and_return(adapter)
      end

      describe 'create_function' do
        it 'creates a function from a file' do
          version         = 15
          definition_stub = instance_double('Definition', to_sql: 'foo')
          allow(Definition).to receive(:new)
                                   .with(:functions, version, :function)
                                   .and_return(definition_stub)

          connection.create_function :functions, version: version

          expect(Scenic.database).to have_received(:create_function).with(definition_stub.to_sql)
        end

        it 'creates a function from a text definition' do
          sql_definition = 'a defintion'

          connection.create_function(:functions, sql_definition: sql_definition)

          expect(Scenic.database).to have_received(:create_function).with(sql_definition)
        end

        it 'creates version 1 of the function if neither version nor sql_defintion are provided' do
          version         = 1
          definition_stub = instance_double('Definition', to_sql: 'foo')
          allow(Definition).to receive(:new).
              with(:functions, version, :function).
              and_return(definition_stub)

          connection.create_function :functions

          expect(Scenic.database).to have_received(:create_function).with(definition_stub.to_sql)
        end

        it 'raises an error if both version and sql_defintion are provided' do
          expect do
            connection.create_function :foo, version: 1, sql_definition: 'a defintion'
          end.to raise_error ArgumentError
        end
      end

      describe 'drop_function' do
        it 'removes a function from the database' do
          connection.drop_function :name

          expect(Scenic.database).to have_received(:drop_function).with(:name, nil)
        end
      end

      describe 'update_function' do
        it 'updates the function in the database' do
          definition = instance_double('Definition', to_sql: 'definition')
          allow(Definition).to receive(:new)
                                   .with(:name, 3, :function)
                                   .and_return(definition)

          connection.update_function(:name, version: 3)

          expect(Scenic.database).to have_received(:update_function)
                                         .with(:name, definition.to_sql)
        end

        it 'updates a function from a text definition' do
          sql_definition = 'a defintion'

          connection.update_function(:name, sql_definition: sql_definition)

          expect(Scenic.database).to have_received(:update_function).
              with(:name, sql_definition)
        end

        it 'raises an error if not supplied a version or sql_defintion' do
          expect { connection.update_function :functions }.to raise_error(
                                                          ArgumentError,
                                                          /sql_definition or version must be specified/)
        end

        it 'raises an error if both version and sql_defintion are provided' do
          expect do
            connection.update_function(
                :functions,
                version:        1,
                sql_definition: 'a defintion')
          end.to raise_error ArgumentError, /cannot both be set/
        end
      end

      def connection
        Class.new { extend FunctionStatements }
      end
    end
  end
end
