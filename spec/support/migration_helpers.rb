module MigrationHelpers

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
    connection.execute(sql)
  end

  def connection
    ActiveRecord::Base.connection
  end

end
