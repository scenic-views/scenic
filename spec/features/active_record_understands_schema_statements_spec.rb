require "spec_helper"

describe "active record understands schema statements", type: :feature do
  it "can run migrations that create views" do
    with_view_definition :greetings, 1, "SELECT text 'hola' AS greeting" do
      create_greetings = Class.new(::ActiveRecord::Migration) do
        def change
          create_view :greetings
        end
      end

      expect { run_migration(create_greetings, :up) }.not_to raise_error
    end
  end

  def run_migration(migration, direction)
    silence_stream(STDOUT) do
      migration.migrate(direction)
    end
  end
end
