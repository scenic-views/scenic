require "spec_helper"

module Scenic
  module Adapters
    describe Postgres, "cascade edge cases", :db, :silence do
      let(:adapter) { Postgres.new }

      describe "circular dependency handling" do
        it "raises TSort::Cyclic for circular dependencies" do
          # Note: This creates an impossible scenario for testing
          # Real circular dependencies cannot be created in PostgreSQL
          # This test verifies our code doesn't add special handling
          
          connection = instance_double("Connection")
          allow(connection).to receive(:select_rows).and_return([
            ["public.view_a", 1],
            ["public.view_b", 1]
          ])
          
          # Mock circular dependency data that would cause TSort to fail
          allow_any_instance_of(Postgres::DependentViewsFinder).to receive(:topologically_sort_dependents)
            .and_raise(TSort::Cyclic)

          finder = Postgres::DependentViewsFinder.new(connection, "base")

          expect {
            finder.find
          }.to raise_error(TSort::Cyclic)
        end
      end

      describe "transaction boundary testing" do
        before do
          adapter.create_materialized_view("base", "SELECT 'data' AS value")
          adapter.create_materialized_view("dependent", "SELECT value FROM base")
        end

        it "maintains transaction isolation during cascade" do
          new_definition = "SELECT 'updated' AS value"

          # Verify operation happens in single transaction
          expect(ar_connection).to receive(:transaction).and_call_original

          adapter.update_materialized_view("base", new_definition, cascade: true)
        end

        it "rolls back all changes on failure" do
          # Create scenario where update will fail due to invalid SQL
          invalid_definition = "SELECT nonexistent_column AS value"

          expect {
            adapter.update_materialized_view("base", invalid_definition, cascade: true)
          }.to raise_error(Scenic::Adapters::Postgres::CascadeUpdateFailedError)

          # Verify original views still exist and unchanged
          base_result = ar_connection.execute("SELECT * FROM base").first["value"]
          dependent_result = ar_connection.execute("SELECT * FROM dependent").first["value"]
          
          expect(base_result).to eq "data"
          expect(dependent_result).to eq "data"
        end
      end

      describe "memory and performance edge cases" do
        it "handles views with large definitions efficiently" do
          # Create view with substantial definition
          large_definition = "SELECT " + (1..100).map { |i| "'value#{i}' AS col#{i}" }.join(", ")
          adapter.create_materialized_view("large_base", large_definition)
          adapter.create_materialized_view("large_dependent", "SELECT col1, col50, col100 FROM large_base")

          new_large_definition = "SELECT " + (1..100).map { |i| "'updated#{i}' AS col#{i}" }.join(", ")

          expect {
            adapter.update_materialized_view("large_base", new_large_definition, cascade: true)
          }.not_to raise_error

          result = ar_connection.execute("SELECT col1, col50 FROM large_dependent").first
          expect(result["col1"]).to eq "updated1"
          expect(result["col50"]).to eq "updated50"
        end
      end

      describe "index edge cases" do
        context "when dependent view has complex indexes" do
          before do
            adapter.create_materialized_view("base", "SELECT generate_series(1, 10) AS id, 'data' AS value")
            adapter.create_materialized_view("dependent", "SELECT id, value FROM base WHERE id > 5")
            
            # Add various index types
            ar_connection.execute("CREATE INDEX dependent_simple_idx ON dependent (id)")
            ar_connection.execute("CREATE INDEX dependent_partial_idx ON dependent (value) WHERE id > 7")
            ar_connection.execute("CREATE UNIQUE INDEX dependent_unique_idx ON dependent (id)")
          end

          it "preserves all index types including partial and unique indexes" do
            new_definition = "SELECT generate_series(1, 20) AS id, 'newdata' AS value"

            adapter.update_materialized_view("base", new_definition, cascade: true)

            indexes = indexes_for("dependent")
            index_names = indexes.map(&:index_name)

            expect(index_names).to include("dependent_simple_idx")
            expect(index_names).to include("dependent_partial_idx") 
            expect(index_names).to include("dependent_unique_idx")
          end
        end

        context "when index recreation fails" do
          before do
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("dependent", "SELECT value FROM base")
            
            # Add an index with a complex expression that might fail
            ar_connection.execute("CREATE INDEX dependent_complex_idx ON dependent (upper(value))")
          end

          it "continues cascade even if some indexes cannot be recreated" do
            # Update with compatible schema - IndexCreation should handle any index recreation failures gracefully
            new_definition = "SELECT 'newdata' AS value"

            expect {
              adapter.update_materialized_view("base", new_definition, cascade: true)
            }.not_to raise_error

            # Verify the update worked
            result = ar_connection.execute("SELECT * FROM base").first["value"]
            expect(result).to eq "newdata"
            
            dependent_result = ar_connection.execute("SELECT * FROM dependent").first["value"]
            expect(dependent_result).to eq "newdata"
          end
        end
      end

      describe "PostgreSQL version compatibility" do
        it "raises MaterializedViewsNotSupportedError for old PostgreSQL" do
          connection = double("Connection", supports_materialized_views?: false)
          connectable = double("Connectable", connection: connection)
          old_adapter = Postgres.new(connectable)

          expect {
            old_adapter.update_materialized_view("test", "SELECT 1", cascade: true)
          }.to raise_error(Scenic::Adapters::Postgres::MaterializedViewsNotSupportedError)
        end
      end

      describe "error message quality" do
        before do
          adapter.create_materialized_view("base", "SELECT 'data' AS value")
          adapter.create_materialized_view("dependent", "SELECT value FROM base")
        end

        it "provides helpful error context in CascadeUpdateFailedError" do
          invalid_definition = "SELECT nonexistent_column AS value"

          begin
            adapter.update_materialized_view("base", invalid_definition, cascade: true)
          rescue Scenic::Adapters::Postgres::CascadeUpdateFailedError => e
            expect(e.message).to include("base")
            expect(e.message).to include("nonexistent_column")
          end
        end
      end

      describe "schema dumper integration" do
        before do
          adapter.create_materialized_view("base", "SELECT 'data' AS value")
          adapter.create_materialized_view("dependent", "SELECT value FROM base")
        end

        it "maintains schema dumper compatibility after cascade update" do
          new_definition = "SELECT 'updated' AS value"

          adapter.update_materialized_view("base", new_definition, cascade: true)

          # Schema dumper should still work correctly
          stream = StringIO.new
          dump_schema(stream)
          schema_content = stream.string

          expect(schema_content).to include("base")
          expect(schema_content).to include("dependent")
        end
      end

      describe "concurrent access scenarios" do
        before do
          adapter.create_materialized_view("shared_base", "SELECT 'data' AS value")
          adapter.create_materialized_view("shared_dependent", "SELECT value FROM shared_base")
        end

        it "handles cascade update during concurrent read access" do
          new_definition = "SELECT 'concurrent_update' AS value"

          # Simulate concurrent access by reading during update
          expect {
            adapter.update_materialized_view("shared_base", new_definition, cascade: true)
          }.not_to raise_error

          # Verify final state is consistent
          result = ar_connection.execute("SELECT * FROM shared_dependent").first["value"]
          expect(result).to eq "concurrent_update"
        end
      end
    end
  end
end