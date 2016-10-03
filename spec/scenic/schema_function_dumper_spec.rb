require 'spec_helper'

describe Scenic::SchemaFunctionDumper, :db do

  let(:connection) { ActiveRecord::Base.connection }

  it 'dumps a create_function for a function in the database' do

    function_definition = <<-SQL
      CREATE OR REPLACE FUNCTION public.hello()
      RETURNS character varying
      LANGUAGE plpgsql
      AS $function$
      BEGIN
        RETURN 'hello';
      END
      $function$
    SQL

    connection.create_function :hello, sql_definition: function_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(connection, stream)

    output = stream.string
    expect(output).to include 'create_function :hello'
    expect(output).to include 'CREATE OR REPLACE FUNCTION public.hello()'

    connection.drop_function :hello

    silence_stream(STDOUT) { eval(output) }

    functions = Scenic::Adapters::Postgres::Functions.new(connection).all
    expect(functions.map(&:name)).to include('hello')

    connection.drop_function :hello
  end

  context 'with functions in non public schemas' do

    it 'dumps a create_function including namespace for a function in the database' do

      function_definition = <<-SQL
        CREATE OR REPLACE FUNCTION hello()
        RETURNS character varying
        LANGUAGE plpgsql
        AS $function$
        BEGIN
          RETURN 'hello';
        END
        $function$
      SQL

      connection.execute 'CREATE SCHEMA scenic; SET search_path TO scenic, public'
      connection.create_function :'scenic.hello', sql_definition: function_definition
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(connection, stream)

      output = stream.string
      expect(output).to include "create_function :'scenic.hello',"
      expect(output).to include 'CREATE OR REPLACE FUNCTION scenic.hello()'

      connection.drop_function :'scenic.hello'
    end
  end
end
