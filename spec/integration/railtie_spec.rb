require "spec_helper"

describe "Scenic railtie", type: :integration do
  around do |example|
    with_view_definition :greetings, 1, "SELECT text 'hola' AS greeting" do
      example.run
    end
  end

  it "Wires up schema statements" do
    expect { run_migration(migration_class, :up) }.not_to raise_error
  end

  it "Wires up the command recorder" do
    expect { run_migration(migration_class, [:up, :down]) }
      .not_to raise_error
  end

  def migration_class
    Class.new(::ActiveRecord::Migration) do
      def change
        create_view :greetings
      end
    end
  end

  def run_migration(migration, directions)
    silence_stream(STDOUT) do
      Array.wrap(directions).each do |direction|
        migration.migrate(direction)
      end
    end
  end
end
