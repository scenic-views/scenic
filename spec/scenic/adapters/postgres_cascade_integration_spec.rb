require "spec_helper"

module Scenic
  module Adapters
    describe Postgres, "cascade update integration", :db, :silence do
      let(:adapter) { Postgres.new }

      describe "#update_materialized_view with cascade: true" do
        context "when view has no dependencies" do
          it "behaves identical to cascade: false" do
            adapter.create_materialized_view("standalone", "SELECT 'hello' AS greeting")
            add_index(:standalone, :greeting, name: "standalone_idx")
            new_definition = "SELECT 'hola' AS greeting"

            # Should work without errors
            adapter.update_materialized_view("standalone", new_definition, cascade: true)

            result = ar_connection.execute("SELECT * FROM standalone").first["greeting"]
            indexes = indexes_for("standalone")

            expect(result).to eq "hola"
            expect(indexes.length).to eq 1
            expect(indexes.first.index_name).to eq "standalone_idx"
          end
        end

        context "when view has simple dependency" do
          before do
            adapter.create_materialized_view("products", "SELECT 'widget' AS name, 100 AS price")
            adapter.create_materialized_view("expensive_products", 
              "SELECT name, price FROM products WHERE price > 50")
            add_index(:products, :name, name: "products_name_idx")
            add_index(:expensive_products, :price, name: "expensive_price_idx")
          end

          it "successfully updates with cascade" do
            new_definition = "SELECT 'gadget' AS name, 200 AS price"

            # This would fail without cascade due to dependent view
            adapter.update_materialized_view("products", new_definition, cascade: true)

            products_result = ar_connection.execute("SELECT * FROM products").first
            expensive_result = ar_connection.execute("SELECT * FROM expensive_products").first

            expect(products_result["name"]).to eq "gadget"
            expect(products_result["price"]).to eq 200
            expect(expensive_result["name"]).to eq "gadget"
            expect(expensive_result["price"]).to eq 200
          end

          it "preserves indexes on all affected views" do
            new_definition = "SELECT 'gadget' AS name, 200 AS price"

            adapter.update_materialized_view("products", new_definition, cascade: true)

            products_indexes = indexes_for("products")
            expensive_indexes = indexes_for("expensive_products")

            expect(products_indexes.first.index_name).to eq "products_name_idx"
            expect(expensive_indexes.first.index_name).to eq "expensive_price_idx"
          end
        end

        context "comparison with cascade: false behavior" do
          before do
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("dependent", "SELECT value FROM base")
          end

          it "fails without cascade when dependencies exist" do
            new_definition = "SELECT 'newdata' AS value"

            expect {
              adapter.update_materialized_view("base", new_definition, cascade: false)
            }.to raise_error(ActiveRecord::StatementInvalid, /cannot drop.*other objects depend/)
          end

          it "succeeds with cascade when dependencies exist" do
            new_definition = "SELECT 'newdata' AS value"

            expect {
              adapter.update_materialized_view("base", new_definition, cascade: true)
            }.not_to raise_error

            result = ar_connection.execute("SELECT * FROM dependent").first["value"]
            expect(result).to eq "newdata"
          end
        end

        context "side_by_side compatibility" do
          before do
            adapter.create_materialized_view("base", "SELECT 'data' AS value")
            adapter.create_materialized_view("dependent", "SELECT value FROM base")
          end

          it "raises error when combining cascade with side_by_side and no_data" do
            new_definition = "SELECT 'newdata' AS value"

            expect {
              adapter.update_materialized_view(
                "base", 
                new_definition, 
                cascade: true, 
                side_by_side: true, 
                no_data: true
              )
            }.to raise_error(ArgumentError, /side_by_side and no_data/)
          end

          it "allows cascade with side_by_side when no_data is false" do
            new_definition = "SELECT 'newdata' AS value"

            expect {
              adapter.update_materialized_view(
                "base", 
                new_definition, 
                cascade: true, 
                side_by_side: true, 
                no_data: false
              )
            }.not_to raise_error
          end

          it "functionally works with side_by_side cascade and preserves dependent view data and indexes" do
            # Create base materialized view
            adapter.create_materialized_view("products", "SELECT 1 AS id, 'widget' AS name, 10.00 AS price")
            
            # Create dependent materialized view
            adapter.create_materialized_view("product_summary", 
              "SELECT name, count(*) AS total, sum(price) AS revenue FROM products GROUP BY name")
            
            # Add indexes to both views
            ar_connection.execute("CREATE INDEX idx_products_name ON products (name)")
            ar_connection.execute("CREATE INDEX idx_summary_name ON product_summary (name)")
            
            # Update base view with side_by_side + cascade
            new_definition = "SELECT 2 AS id, 'gadget' AS name, 15.00 AS price UNION ALL SELECT 3 AS id, 'gadget' AS name, 20.00 AS price"
            
            expect {
              adapter.update_materialized_view(
                "products", 
                new_definition, 
                cascade: true, 
                side_by_side: true, 
                no_data: false
              )
            }.not_to raise_error
            
            # Verify base view data updated correctly
            products_result = ar_connection.execute("SELECT * FROM products ORDER BY id")
            expect(products_result.count).to eq 2
            expect(products_result.first["name"]).to eq "gadget"
            expect(products_result.first["price"].to_f).to eq 15.00
            
            # Verify dependent view was recreated with correct data
            summary_result = ar_connection.execute("SELECT * FROM product_summary").first
            expect(summary_result["name"]).to eq "gadget"
            expect(summary_result["total"].to_i).to eq 2
            expect(summary_result["revenue"].to_f).to eq 35.00
            
            # Verify indexes were preserved on both views
            products_indexes = ar_connection.execute(<<-SQL)
              SELECT indexname FROM pg_indexes 
              WHERE tablename = 'products' AND indexname != 'products_pkey'
            SQL
            expect(products_indexes.map { |row| row["indexname"] }).to include("idx_products_name")
            
            summary_indexes = ar_connection.execute(<<-SQL)
              SELECT indexname FROM pg_indexes 
              WHERE tablename = 'product_summary' AND indexname != 'product_summary_pkey'
            SQL
            expect(summary_indexes.map { |row| row["indexname"] }).to include("idx_summary_name")
            
            # Verify both views are materialized
            products_view = ar_connection.execute(<<-SQL)
              SELECT relkind FROM pg_class WHERE relname = 'products'
            SQL
            expect(products_view.first["relkind"]).to eq "m"
            
            summary_view = ar_connection.execute(<<-SQL)
              SELECT relkind FROM pg_class WHERE relname = 'product_summary'  
            SQL
            expect(summary_view.first["relkind"]).to eq "m"
          end
        end

        context "performance and resource management" do
          it "handles reasonable dependency chains efficiently" do
            # Create 5-level hierarchy
            adapter.create_materialized_view("level0", "SELECT generate_series(1, 100) AS id")
            (1..4).each do |i|
              adapter.create_materialized_view("level#{i}", "SELECT id FROM level#{i-1}")
            end

            new_definition = "SELECT generate_series(1, 50) AS id"
            start_time = Time.current

            adapter.update_materialized_view("level0", new_definition, cascade: true)

            execution_time = Time.current - start_time
            expect(execution_time).to be < 30.seconds  # Reasonable performance threshold
          end
        end

        context "data consistency verification" do
          before do
            adapter.create_materialized_view("orders", 
              "SELECT 1 AS id, 'pending' AS status, 100.00 AS amount")
            adapter.create_materialized_view("order_totals", 
              "SELECT status, sum(amount) AS total FROM orders GROUP BY status")
          end

          it "maintains data consistency across dependency chain" do
            new_definition = "SELECT 1 AS id, 'completed' AS status, 150.00 AS amount"

            adapter.update_materialized_view("orders", new_definition, cascade: true)

            orders_result = ar_connection.execute("SELECT * FROM orders").first
            totals_result = ar_connection.execute("SELECT * FROM order_totals").first

            expect(orders_result["status"]).to eq "completed"
            expect(orders_result["amount"].to_f).to eq 150.0
            expect(totals_result["status"]).to eq "completed"
            expect(totals_result["total"].to_f).to eq 150.0
          end
        end
      end
    end
  end
end