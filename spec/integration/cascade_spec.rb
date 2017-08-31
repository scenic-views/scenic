require "spec_helper"

describe "Dropping a view and its dependencies with cascade", :db do
  around do |example|
    with_view_definition :greetings, 1, "SELECT text 'hola' as greeting" do
      with_view_definition :dependent_greetings, 1, "SELECT * from greetings" do
        example.run
      end
    end
  end

  it 'works' do
    run_migration(migration_for_create, :up)
    expect {
      run_migration(migration_for_drop, :up)
    }.to_not raise_error
  end

  describe 'as part of updating a view' do
    around do |example|
      with_view_definition :greetings, 2, "SELECT text 'good day' AS greeting" do
        example.run
      end
    end

    it 'recreates the dependent view' do
      views = Scenic::Adapters::Postgres::Views.new(connection)
      run_migration(migration_for_create, :up)
      expect {
        run_migration(migration_for_update, :up)
      }.to_not change {
        views.all.length
      }
    end

    it 'recreates indexes on the dependent view' do
      indexes = Scenic::Adapters::Postgres::Indexes.new(connection: connection)
      run_migration(migration_for_create_materialized_dependent, :up)
      run_migration(index_migration, :up)
      expect {
        run_migration(migration_for_update, :up)
      }.to_not change {
        indexes.on('dependent_greetings')
      }
    end

    it 'reverts' do
      run_migration(migration_for_create, :up)
      run_migration(migration_for_update, :up)
      run_migration(migration_for_update, :down)
      greeting = execute("SELECT * FROM dependent_greetings")[0]["greeting"]
      expect(greeting).to eq 'hola'
    end
  end

  def migration_for_create
    Class.new(migration_class) do
      def change
        create_view :greetings
        create_view :dependent_greetings
      end
    end
  end

  def migration_for_create_materialized_dependent
    Class.new(migration_class) do
      def change
        create_view :greetings
        create_view :dependent_greetings, materialized: true
      end
    end
  end

  def migration_for_drop
    Class.new(migration_class) do
      def change
        drop_view :greetings, revert_to_version: 1, cascade: true
      end
    end
  end

  def migration_for_update
    Class.new(migration_class) do
      def change
        update_view :greetings, version: 2, revert_to_version: 1, cascade: true
      end
    end
  end

  def index_migration
    Class.new(migration_class) do
      def change
        add_index :dependent_greetings, :greeting
      end
    end
  end


end
