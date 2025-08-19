require "spec_helper"

module Scenic
  describe Statements, "cascade support" do
    before do
      adapter = instance_double("Scenic::Adapters::Postgres").as_null_object
      allow(Scenic).to receive(:database).and_return(adapter)
    end

    describe "#update_view with materialized cascade options" do
      let(:definition) { instance_double("Definition", to_sql: "definition") }

      before do
        allow(Definition).to receive(:new).and_return(definition)
      end

      it "passes cascade option to adapter" do
        connection = DummyConnection.new(transactions_enabled: true)

        expect(Scenic.database).to receive(:update_materialized_view).with(
          :name,
          "definition",
          no_data: false,
          side_by_side: false,
          cascade: true
        )

        connection.update_view(
          :name,
          version: 1,
          materialized: { cascade: true }
        )
      end

      it "defaults cascade to false when not specified" do
        connection = DummyConnection.new(transactions_enabled: true)

        expect(Scenic.database).to receive(:update_materialized_view).with(
          :name,
          "definition", 
          no_data: false,
          side_by_side: false,
          cascade: false
        )

        connection.update_view(
          :name,
          version: 1,
          materialized: true
        )
      end

      it "supports cascade with other materialized options" do
        connection = DummyConnection.new(transactions_enabled: true)

        expect(Scenic.database).to receive(:update_materialized_view).with(
          :name,
          "definition",
          no_data: true,
          side_by_side: false,
          cascade: true
        )

        connection.update_view(
          :name,
          version: 1,
          materialized: { 
            cascade: true, 
            no_data: true 
          }
        )
      end

      it "handles cascade with side_by_side option" do
        connection = DummyConnection.new(transactions_enabled: true)

        expect(Scenic.database).to receive(:update_materialized_view).with(
          :name,
          "definition",
          no_data: false,
          side_by_side: true,
          cascade: true
        )

        connection.update_view(
          :name,
          version: 1,
          materialized: { 
            cascade: true,
            side_by_side: true
          }
        )
      end

      it "does not pass cascade option for regular views" do
        connection = DummyConnection.new(transactions_enabled: true)

        expect(Scenic.database).to receive(:update_view).with(:name, "definition")
        expect(Scenic.database).not_to receive(:update_materialized_view)

        connection.update_view(
          :name,
          version: 1,
          materialized: false
        )
      end
    end

    def connection(transactions_enabled: true)
      DummyConnection.new(transactions_enabled: transactions_enabled)
    end
  end

  class DummyConnection
    include Statements

    def initialize(transactions_enabled: true)
      @transactions_enabled = transactions_enabled
    end

    def transaction_open?
      @transactions_enabled
    end
  end
end