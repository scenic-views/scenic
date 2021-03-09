require "spec_helper"

module Scenic
  module Adapters
    describe Postgres, :db do
      describe "#create_view" do
        it "successfully creates a view" do
          adapter = Postgres.new

          adapter.create_view("greetings", "SELECT text 'hi' AS greeting")

          expect(adapter.views.map(&:name)).to include("greetings")
        end
      end

      describe "#create_materialized_view" do
        it "successfully creates a materialized view" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )

          view = adapter.views.first
          expect(view.name).to eq("greetings")
          expect(view.materialized).to eq true
        end

        it "handles semicolon in definition when using `with no data`" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting; \n",
            no_data: true,
          )

          view = adapter.views.first
          expect(view.name).to eq("greetings")
          expect(view.materialized).to eq true
        end

        it "copy indexes from another view" do
          adapter = Postgres.new
          connection = ActiveRecord::Base.connection

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting; \n",
          )
          connection.add_index :greetings, :greeting
          adapter.create_materialized_view(
            "greetings_nexts",
            "SELECT text 'hello' AS greeting; \n",
            copy_indexes_from: :greetings,
          )

          indexes = Postgres::Indexes.new(connection: connection)
          index_names = indexes.on("greetings_nexts").map(&:index_name)
          expect(index_names).to include("index_greetings_nexts_on_greeting")
        end

        it "raises an exception if the version of PostgreSQL is too old" do
          connection = double("Connection", supports_materialized_views?: false)
          connectable = double("Connectable", connection: connection)
          adapter = Postgres.new(connectable)
          err = Scenic::Adapters::Postgres::MaterializedViewsNotSupportedError

          expect { adapter.create_materialized_view("greetings", "select 1") }
            .to raise_error err
        end
      end

      describe "#replace_view" do
        it "successfully replaces a view" do
          adapter = Postgres.new

          adapter.create_view("greetings", "SELECT text 'hi' AS greeting")

          view = adapter.views.first.definition
          expect(view).to eql "SELECT 'hi'::text AS greeting;"

          adapter.replace_view("greetings", "SELECT text 'hello' AS greeting")

          view = adapter.views.first.definition
          expect(view).to eql "SELECT 'hello'::text AS greeting;"
        end
      end

      describe "#drop_view" do
        it "successfully drops a view" do
          adapter = Postgres.new

          adapter.create_view("greetings", "SELECT text 'hi' AS greeting")
          adapter.drop_view("greetings")

          expect(adapter.views.map(&:name)).not_to include("greetings")
        end
      end

      describe "#rename_view" do
        it "successfully drops a view" do
          adapter = Postgres.new

          adapter.create_view("greetings", "SELECT text 'hi' AS greeting")
          adapter.rename_view("greetings", "renamed")

          expect(adapter.views.map(&:name)).not_to include("greetings")
          expect(adapter.views.map(&:name)).to include("renamed")
        end
      end

      describe "#replace_materialized_view" do
        it "successfully replaces a view" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "greetings", "SELECT text 'hi' AS greeting"
          )
          adapter.create_materialized_view(
            "greetings_next", "SELECT text 'hello' AS greeting"
          )

          from_view = adapter.views.find { |view| view.name == "greetings" }
          expect(from_view.definition).to eql "SELECT 'hi'::text AS greeting;"

          adapter.replace_materialized_view("greetings_next", "greetings")

          to_view = adapter.views.find { |view| view.name == "greetings" }
          expect(to_view.definition).to eql "SELECT 'hello'::text AS greeting;"
        end
      end

      describe "#drop_materialized_view" do
        it "successfully drops a materialized view" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )
          adapter.drop_materialized_view("greetings")

          expect(adapter.views.map(&:name)).not_to include("greetings")
        end

        it "raises an exception if the version of PostgreSQL is too old" do
          connection = double("Connection", supports_materialized_views?: false)
          connectable = double("Connectable", connection: connection)
          adapter = Postgres.new(connectable)
          err = Scenic::Adapters::Postgres::MaterializedViewsNotSupportedError

          expect { adapter.drop_materialized_view("greetings") }
            .to raise_error err
        end
      end

      describe "#rename_materialized_view" do
        it "successfully renames a materialized view" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )
          adapter.rename_materialized_view("greetings", "renamed")

          expect(adapter.views.map(&:name)).not_to include("greetings")
          expect(adapter.views.map(&:name)).to include("renamed")
        end

        it "successfully renames materialized view indexes" do
          adapter = Postgres.new
          connection = ActiveRecord::Base.connection

          adapter.create_materialized_view(
            "greetings",
            "SELECT text 'hi' AS greeting",
          )
          connection.add_index :greetings, :greeting
          adapter.rename_materialized_view(
            "greetings",
            "renamed",
            rename_indexes: true,
          )

          connection = ActiveRecord::Base.connection
          indexes = Postgres::Indexes.new(connection: connection)
          index_names = indexes.on("renamed").map(&:index_name)
          expect(index_names).to include("index_renamed_on_greeting")
        end

        it "raises an exception if the version of PostgreSQL is too old" do
          connection = double("Connection", supports_materialized_views?: false)
          connectable = double("Connectable", connection: connection)
          adapter = Postgres.new(connectable)
          err = Scenic::Adapters::Postgres::MaterializedViewsNotSupportedError

          expect { adapter.rename_materialized_view("greetings", "renamed") }
            .to raise_error err
        end
      end

      describe "#refresh_materialized_view" do
        it "raises an exception if the version of PostgreSQL is too old" do
          connection = double("Connection", supports_materialized_views?: false)
          connectable = double("Connectable", connection: connection)
          adapter = Postgres.new(connectable)
          err = Scenic::Adapters::Postgres::MaterializedViewsNotSupportedError

          expect { adapter.refresh_materialized_view(:tests) }
            .to raise_error err
        end

        it "can refresh the views dependencies first" do
          connection = double("Connection").as_null_object
          connectable = double("Connectable", connection: connection)
          adapter = Postgres.new(connectable)
          expect(Scenic::Adapters::Postgres::RefreshDependencies)
            .to receive(:call)
            .with(:tests, adapter, connection, concurrently: true)

          adapter.refresh_materialized_view(
            :tests,
            cascade: true,
            concurrently: true,
          )
        end

        context "refreshing concurrently" do
          it "raises descriptive error if concurrent refresh is not possible" do
            adapter = Postgres.new
            adapter.create_materialized_view(:tests, "SELECT text 'hi' as text")

            expect {
              adapter.refresh_materialized_view(:tests, concurrently: true)
            }.to raise_error(/Create a unique index with no WHERE clause/)
          end

          it "raises an exception if the version of PostgreSQL is too old" do
            connection = double("Connection", postgresql_version: 90300)
            connectable = double("Connectable", connection: connection)
            adapter = Postgres.new(connectable)
            e = Scenic::Adapters::Postgres::ConcurrentRefreshesNotSupportedError

            expect {
              adapter.refresh_materialized_view(:tests, concurrently: true)
            }.to raise_error e
          end
        end
      end

      describe "#views" do
        it "returns the views defined on this connection" do
          adapter = Postgres.new

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE VIEW parents AS SELECT text 'Joe' AS name
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE VIEW children AS SELECT text 'Owen' AS name
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE MATERIALIZED VIEW people AS
            SELECT name FROM parents UNION SELECT name FROM children
          SQL

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE VIEW people_with_names AS
            SELECT name FROM people
            WHERE name IS NOT NULL
          SQL

          expect(adapter.views.map(&:name)).to eq [
            "parents",
            "children",
            "people",
            "people_with_names",
          ]
        end

        context "with views in non public schemas" do
          it "returns also the non public views" do
            adapter = Postgres.new

            ActiveRecord::Base.connection.execute <<-SQL
              CREATE VIEW parents AS SELECT text 'Joe' AS name
            SQL

            ActiveRecord::Base.connection.execute <<-SQL
              CREATE SCHEMA scenic;
              CREATE VIEW scenic.parents AS SELECT text 'Maarten' AS name;
              SET search_path TO scenic, public;
            SQL

            expect(adapter.views.map(&:name)).to eq [
              "parents",
              "scenic.parents",
            ]
          end
        end
      end

      describe "#normalize_sql" do
        it "returns scenic view objects for plain old views" do
          adapter = Postgres.new
          expect(adapter.normalize_sql("SELECT text 'Elliot' AS name"))
            .to eq("SELECT 'Elliot'::text AS name;")
        end
        it "allow to normalize multiple queries on the same transaction" do
          adapter = Postgres.new
          ActiveRecord::Base.connection.transaction do
            expect do
              adapter.normalize_sql("SELECT text 'Elliot' AS name")
              adapter.normalize_sql("SELECT text 'John' AS first_name")
            end.to_not raise_error
          end
        end
      end
      describe "#normalize_sql" do
        it "returns scenic view objects for plain old views" do
          adapter = Postgres.new
          ActiveRecord::Base.connection.execute <<-SQL
            CREATE VIEW children AS SELECT text 'Elliot' AS name
          SQL

          expect(adapter.normalize_view_sql("children"))
            .to eq("SELECT 'Elliot'::text AS name;")
        end

        it "returns scenic view objects for materialized views" do
          adapter = Postgres.new
          ActiveRecord::Base.connection.execute <<-SQL
            CREATE MATERIALIZED VIEW children AS SELECT text 'Elliot' AS name
          SQL

          expect(adapter.normalize_view_sql("children"))
            .to eq("SELECT 'Elliot'::text AS name;")
        end
      end

      describe "#view_with_similar_definition?" do
        context "when the view has a similar definition" do
          it "returns true" do
            adapter = Postgres.new
            ActiveRecord::Base.connection.execute <<~SQL
              CREATE VIEW greetings AS SELECT text 'hi' AS greeting
            SQL

            sql_defintion = <<~SQL
              SELECT text 'hi'
              AS greeting
            SQL
            definition = instance_double(
              "Scenic::Definition",
              name: "greetings", to_sql: sql_defintion,
            )

            expect(
              adapter.view_with_similar_definition?(definition),
            ).to be(true)
          end
        end
        context "when the view doesn't exists on the database" do
          it "returns false" do
            adapter = Postgres.new

            definition = instance_double(
              "Scenic::Definition",
              name: "greetings", to_sql: "SELECT text 'hi' AS greeting",
            )

            expect(
              adapter.view_with_similar_definition?(definition),
            ).to be(false)
          end
        end
        context "when the view has a different definition" do
          it "returns false" do
            adapter = Postgres.new
            ActiveRecord::Base.connection.execute <<~SQL
              CREATE VIEW greetings AS SELECT text 'hi' AS hello
            SQL

            definition = instance_double(
              "Scenic::Definition",
              name: "greetings", to_sql: "SELECT text 'hi' AS greeting",
            )

            expect(
              adapter.view_with_similar_definition?(definition),
            ).to be(false)
          end
        end
      end
    end
  end
end
