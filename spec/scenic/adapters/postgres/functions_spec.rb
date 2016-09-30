require 'spec_helper'

module Scenic
  module Adapters
    describe Postgres::Functions, :db do

      let(:hello_bob_function) do
        <<-SQL
          CREATE OR REPLACE FUNCTION hello_bob()
          RETURNS character varying
          LANGUAGE plpgsql
          AS $function$
          BEGIN
            RETURN 'hello bob';
          END
          $function$
        SQL
      end

      let(:hello_dave_function) do
        <<-SQL
          CREATE OR REPLACE FUNCTION hello_dave()
          RETURNS character varying
          LANGUAGE plpgsql
          AS $function$
          BEGIN
            RETURN 'hello dave';
          END
          $function$
        SQL
      end

      let(:connection) { ActiveRecord::Base.connection }

      before(:each) do
        connection.execute(hello_bob_function)
        connection.execute(hello_dave_function)
      end

      after(:each) do
        connection.execute('DROP FUNCTION IF EXISTS hello_bob();')
        connection.execute('DROP FUNCTION IF EXISTS hello_dave();')
      end

      let(:functions) { Postgres::Functions.new(connection).all }

      it 'returns a scenic function object for each function' do
        expect(functions.size).to eq 2
      end

      describe 'the first function' do

        let(:first_function) { functions.first }

        it 'returns "hello_bob" as the function name' do
          expect(first_function.name).to eq('hello_bob')
        end

        it 'returns the correct function definition' do
          expect(first_function.definition.gsub(/\s/,'')).to eq(hello_bob_function.gsub(/\s/,''))
        end
      end

      describe 'the second function' do

        let(:second_function) { functions.second }

        it 'returns "hello_dave" as the function name' do
          expect(second_function.name).to eq('hello_dave')
        end

        it 'returns the correct function definition' do
          expect(second_function.definition.gsub(/\s/,'')).to eq(hello_dave_function.gsub(/\s/,''))
        end
      end
    end
  end
end
