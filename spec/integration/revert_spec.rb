require "spec_helper"

describe "Reverting scenic schema statements", :db do
  around do |example|
    with_view_definition :greetings, 1, "SELECT text 'hola' AS greeting" do
      example.run
    end
  end

  it "reverts dropped view to specified version" do
    run_migration(migration_for_create, :up)
    run_migration(migration_for_drop, :up)
    run_migration(migration_for_drop, :down)

    expect { execute("SELECT * from greetings") }
      .not_to raise_error
  end

  it "reverts updated view to specified version" do
    with_view_definition :greetings, 2, "SELECT text 'good day' AS greeting" do
      run_migration(migration_for_create, :up)
      run_migration(migration_for_update, :up)
      run_migration(migration_for_update, :down)

      greeting = execute("SELECT * from greetings")[0]["greeting"]

      expect(greeting).to eq "hola"
    end
  end

  def migration_for_create
    Class.new(migration_class) do
      def change
        create_view :greetings
      end
    end
  end

  def migration_for_drop
    Class.new(migration_class) do
      def change
        drop_view :greetings, revert_to_version: 1
      end
    end
  end

  def migration_for_update
    Class.new(migration_class) do
      def change
        update_view :greetings, version: 2, revert_to_version: 1
      end
    end
  end

  def migration_class
    if Rails::VERSION::MAJOR >= 5
      ::ActiveRecord::Migration[5.0]
    else
      ::ActiveRecord::Migration
    end
  end

  def run_migration(migration, directions)
    silence_stream(STDOUT) do
      Array.wrap(directions).each do |direction|
        migration.migrate(direction)
      end
    end
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end
