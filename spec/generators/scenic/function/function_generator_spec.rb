require 'spec_helper'
require 'generators/scenic/function/function_generator'

describe Scenic::Generators::FunctionGenerator, :generator do
  it 'creates function definition and migration files' do
    migration = file('db/migrate/create_say_hello.rb')
    function_definition = file('db/functions/say_hello_v01.sql')

    run_generator ['say_hello']

    expect(migration).to be_a_migration
    expect(function_definition).to exist
  end

  it 'updates an existing function' do
    with_function_definition('say_hello', 1, 'say_hello') do
      migration = file('db/migrate/update_say_hello_to_version_2.rb')
      function_definition = file('db/functions/say_hello_v02.sql')
      allow(Dir).to receive(:entries).and_return(['say_hello_v01.sql'])

      run_generator ['say_hello']

      expect(migration).to be_a_migration
      expect(function_definition).to exist
    end
  end
end
