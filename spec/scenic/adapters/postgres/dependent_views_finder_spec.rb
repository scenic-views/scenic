require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::DependentViewsFinder, :db do
      let(:connection) { ActiveRecord::Base.connection }
      let(:adapter) { Postgres.new }

      describe "#find" do
        context "when view has no dependencies" do
          before do
            adapter.create_materialized_view("isolated", "SELECT 'standalone' AS value")
          end

          it "returns empty array" do
            finder = described_class.new(connection, "isolated")
            
            expect(finder.find).to eq []
          end
        end

        context "when view has single dependent" do
          before do
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("dependent", "SELECT value FROM base")
          end

          it "returns single dependent view" do
            finder = described_class.new(connection, "base")
            
            expect(finder.find).to eq ["public.dependent"]
          end
        end

        context "when view has multiple direct dependents" do
          before do
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("dep1", "SELECT value AS v1 FROM base")
            adapter.create_materialized_view("dep2", "SELECT value AS v2 FROM base")
          end

          it "returns all direct dependents" do
            finder = described_class.new(connection, "base")
            dependents = finder.find
            
            expect(dependents).to include("public.dep1", "public.dep2")
            expect(dependents.length).to eq 2
          end
        end

        context "when view has nested dependency hierarchy" do
          before do
            # Create: base → level1 → level2 → level3
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("level1", "SELECT value FROM base")
            adapter.create_materialized_view("level2", "SELECT value FROM level1")
            adapter.create_materialized_view("level3", "SELECT value FROM level2")
          end

          it "returns dependents in correct topological order" do
            finder = described_class.new(connection, "base")
            dependents = finder.find
            
            expect(dependents).to eq ["public.level1", "public.level2", "public.level3"]
          end
        end

        context "when view has diamond dependency pattern" do
          before do
            # Create diamond: base → left_path, right_path → convergence
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("left_path", "SELECT value || '_left' AS left_value FROM base")
            adapter.create_materialized_view("right_path", "SELECT value || '_right' AS right_value FROM base")
            adapter.create_materialized_view("convergence", 
              "SELECT left_tbl.left_value, right_tbl.right_value FROM left_path left_tbl, right_path right_tbl")
          end

          it "returns all dependents in valid topological order" do
            finder = described_class.new(connection, "base")
            dependents = finder.find
            
            # Should include all dependents
            expect(dependents).to include("public.left_path", "public.right_path", "public.convergence")
            expect(dependents.length).to eq 3
            
            # Convergence should come after left_path and right_path
            convergence_index = dependents.index("public.convergence")
            left_index = dependents.index("public.left_path")
            right_index = dependents.index("public.right_path")
            
            expect(convergence_index).to be > left_index
            expect(convergence_index).to be > right_index
          end
        end

        context "when view has mixed materialized and regular view dependencies" do
          before do
            adapter.create_materialized_view("materialized_base", "SELECT 'data' AS value")
            ar_connection.execute("CREATE VIEW regular_middle AS SELECT value FROM materialized_base")
            adapter.create_materialized_view("materialized_top", "SELECT value FROM regular_middle")
          end

          it "finds dependencies across view types" do
            finder = described_class.new(connection, "materialized_base")
            dependents = finder.find
            
            expect(dependents).to include("public.regular_middle", "public.materialized_top")
            expect(dependents.length).to eq 2
          end
        end

        context "when view has cross-schema dependencies" do
          before do
            ar_connection.execute("CREATE SCHEMA test_schema")
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            ar_connection.execute("CREATE MATERIALIZED VIEW test_schema.cross_schema_dep AS SELECT value FROM public.base")
          end

          after do
            ar_connection.execute("DROP SCHEMA IF EXISTS test_schema CASCADE")
          end

          it "finds cross-schema dependents" do
            finder = described_class.new(connection, "base")
            dependents = finder.find
            
            expect(dependents).to include("test_schema.cross_schema_dep")
          end
        end

        context "when view name contains special characters" do
          before do
            ar_connection.execute('CREATE MATERIALIZED VIEW "special-base" AS SELECT \'data\' AS value')
            ar_connection.execute('CREATE MATERIALIZED VIEW "special-dependent" AS SELECT value FROM "special-base"')
          end

          it "handles quoted identifiers correctly" do
            finder = described_class.new(connection, "special-base")
            dependents = finder.find
            
            expect(dependents).to include("public.special-dependent")
          end
        end
      end
    end
  end
end