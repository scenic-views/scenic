require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::UpdateWithCascade, :db, :silence do
      let(:adapter) { Postgres.new }
      let(:speaker) { instance_double("ActiveRecord::Migration", say: nil) }

      describe "#update" do
        context "when view has no dependencies" do
          it "delegates to standard update implementation" do
            create_materialized_view("standalone", "SELECT 'hello' AS greeting")
            add_index(:standalone, :greeting, name: "standalone_greeting_idx")
            new_definition = "SELECT 'hola' AS greeting"

            described_class.new(
              adapter: adapter,
              name: "standalone",
              definition: new_definition,
            ).update

            result = ar_connection.execute("SELECT * FROM standalone").first["greeting"]
            indexes = indexes_for("standalone")

            expect(result).to eq "hola"
            expect(indexes.length).to eq 1
            expect(indexes.first.index_name).to eq "standalone_greeting_idx"
          end
        end

        context "when view has simple dependency chain" do
          before do
            # Create: base → dependent
            adapter.create_materialized_view("base", "SELECT 'original' AS value")
            adapter.create_materialized_view("dependent", "SELECT value || '_dep' AS result FROM base")
            add_index(:base, :value, name: "base_value_idx")
            add_index(:dependent, :result, name: "dependent_result_idx")
          end

          it "updates base view and recreates dependent with new data" do
            new_definition = "SELECT 'updated' AS value"

            described_class.new(
              adapter: adapter,
              name: "base",
              definition: new_definition,
            ).update

            base_result = ar_connection.execute("SELECT * FROM base").first["value"]
            dependent_result = ar_connection.execute("SELECT * FROM dependent").first["result"]

            expect(base_result).to eq "updated"
            expect(dependent_result).to eq "updated_dep"
          end

          it "preserves indexes on both base and dependent views" do
            new_definition = "SELECT 'updated' AS value"

            described_class.new(
              adapter: adapter,
              name: "base", 
              definition: new_definition,
            ).update

            base_indexes = indexes_for("base")
            dependent_indexes = indexes_for("dependent")

            expect(base_indexes.length).to eq 1
            expect(base_indexes.first.index_name).to eq "base_value_idx"
            expect(dependent_indexes.length).to eq 1
            expect(dependent_indexes.first.index_name).to eq "dependent_result_idx"
          end

          it "handles transaction rollback on failure" do
            new_definition = "SELECT invalid_column AS value"  # This will fail

            expect {
              described_class.new(
                adapter: adapter,
                name: "base",
                definition: new_definition,
              ).update
            }.to raise_error(Scenic::Adapters::Postgres::CascadeUpdateFailedError)

            # Original views should still exist
            expect(adapter.views.map(&:name)).to include("base", "dependent")
            base_result = ar_connection.execute("SELECT * FROM base").first["value"]
            expect(base_result).to eq "original"
          end
        end

        context "when view has complex dependency hierarchy" do
          before do
            # Create: base → level1 → level2 → level3
            adapter.create_materialized_view("base", "SELECT 'data' AS value, 1 AS id")
            adapter.create_materialized_view("level1", "SELECT value || '_l1' AS result, id FROM base")
            adapter.create_materialized_view("level2", "SELECT result || '_l2' AS final_result, id FROM level1")
            adapter.create_materialized_view("level3", "SELECT final_result || '_l3' AS ultimate, id FROM level2")
            
            # Add indexes to verify preservation
            add_index(:base, :id, name: "base_id_idx")
            add_index(:level1, :id, name: "level1_id_idx")
            add_index(:level2, :id, name: "level2_id_idx")
            add_index(:level3, :id, name: "level3_id_idx")
          end

          it "updates entire hierarchy maintaining data flow" do
            new_definition = "SELECT 'newdata' AS value, 1 AS id"

            described_class.new(
              adapter: adapter,
              name: "base",
              definition: new_definition,
            ).update

            level3_result = ar_connection.execute("SELECT * FROM level3").first["ultimate"]
            expect(level3_result).to eq "newdata_l1_l2_l3"
          end

          it "preserves all indexes across hierarchy" do
            new_definition = "SELECT 'newdata' AS value, 1 AS id"

            described_class.new(
              adapter: adapter,
              name: "base",
              definition: new_definition,
            ).update

            %w[base level1 level2 level3].each do |view_name|
              indexes = indexes_for(view_name)
              expect(indexes.length).to eq 1
              expect(indexes.first.index_name).to eq "#{view_name}_id_idx"
            end
          end

          it "drops and recreates views in correct order" do
            new_definition = "SELECT 'newdata' AS value, 1 AS id"

            # Verify order by mocking the adapter calls
            allow(adapter).to receive(:drop_materialized_view).and_call_original
            allow(adapter).to receive(:create_materialized_view).and_call_original

            described_class.new(
              adapter: adapter,
              name: "base",
              definition: new_definition,
            ).update

            # Verify drop order (reverse dependency): level3 → level2 → level1 → base
            expect(adapter).to have_received(:drop_materialized_view).with("level3").ordered
            expect(adapter).to have_received(:drop_materialized_view).with("level2").ordered
            expect(adapter).to have_received(:drop_materialized_view).with("level1").ordered
            expect(adapter).to have_received(:drop_materialized_view).with("base").ordered

            # Verify creation order: base → level1 → level2 → level3
            expect(adapter).to have_received(:create_materialized_view).with("base", new_definition, {no_data: false}).ordered
            expect(adapter).to have_received(:create_materialized_view).with("level1", anything).ordered
            expect(adapter).to have_received(:create_materialized_view).with("level2", anything).ordered
            expect(adapter).to have_received(:create_materialized_view).with("level3", anything).ordered
          end
        end

        context "when view has mixed materialized and regular view dependencies" do
          before do
            # Create: materialized_base → regular_view → materialized_summary
            adapter.create_materialized_view("materialized_base", "SELECT 'data' AS value")
            ar_connection.execute("CREATE VIEW regular_view AS SELECT value || '_regular' AS processed FROM materialized_base")
            adapter.create_materialized_view("materialized_summary", "SELECT processed || '_summary' AS final FROM regular_view")
          end

          it "handles mixed view types correctly" do
            new_definition = "SELECT 'newdata' AS value"

            described_class.new(
              adapter: adapter,
              name: "materialized_base",
              definition: new_definition,
            ).update

            summary_result = ar_connection.execute("SELECT * FROM materialized_summary").first["final"]
            expect(summary_result).to eq "newdata_regular_summary"
          end

          it "recreates views with correct types" do
            new_definition = "SELECT 'newdata' AS value"

            described_class.new(
              adapter: adapter,
              name: "materialized_base",
              definition: new_definition,
            ).update

            views = adapter.views
            materialized_base = views.find { |v| v.name == "materialized_base" }
            regular_view = views.find { |v| v.name == "regular_view" }
            materialized_summary = views.find { |v| v.name == "materialized_summary" }

            expect(materialized_base.materialized).to be true
            expect(regular_view.materialized).to be false
            expect(materialized_summary.materialized).to be true
          end
        end

        context "when using side_by_side option" do
          it "raises error with side_by_side and no_data combination" do
            create_materialized_view("base", "SELECT 'data' AS value")

            expect {
              described_class.new(
                adapter: adapter,
                name: "base",
                definition: "SELECT 'new' AS value",
                side_by_side: true,
                no_data: true,
              ).update
            }.to raise_error(ArgumentError, /side_by_side and no_data/)
          end
        end

        context "error handling" do
          before do
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("dependent", "SELECT value FROM base")
          end

          it "wraps errors in CascadeUpdateFailedError" do
            invalid_definition = "SELECT invalid_column AS value"

            expect {
              described_class.new(
                adapter: adapter,
                name: "base",
                definition: invalid_definition,
              ).update
            }.to raise_error(Scenic::Adapters::Postgres::CascadeUpdateFailedError, /Failed to update materialized view 'base'/)
          end

          it "preserves original error details in message" do
            invalid_definition = "SELECT invalid_column AS value"

            begin
              described_class.new(
                adapter: adapter,
                name: "base",
                definition: invalid_definition,
              ).update
            rescue Scenic::Adapters::Postgres::CascadeUpdateFailedError => e
              expect(e.message).to include("base")
              expect(e.message).to include("invalid_column")
            end
          end
        end

      end
    end
  end
end