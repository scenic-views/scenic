require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::RefreshDependencies, :db do
      context "view has dependencies" do
        let(:adapter) { Postgres.new }

        before do
          adapter.create_materialized_view(
            "first",
            "SELECT text 'hi' AS greeting",
          )
          adapter.create_materialized_view(
            "second",
            "SELECT * FROM first",
          )
          adapter.create_materialized_view(
            "third",
            "SELECT * FROM first UNION SELECT * FROM second",
          )
          adapter.create_materialized_view(
            "fourth_1",
            "SELECT * FROM third",
          )
          adapter.create_materialized_view(
            "x_fourth",
            "SELECT * FROM fourth_1",
          )
          adapter.create_materialized_view(
            "fourth",
            "SELECT * FROM fourth_1 UNION SELECT * FROM x_fourth",
          )

          expect(adapter).to receive(:refresh_materialized_view)
            .with("public.first", concurrently: true).ordered
          expect(adapter).to receive(:refresh_materialized_view)
            .with("public.second", concurrently: true).ordered
          expect(adapter).to receive(:refresh_materialized_view)
            .with("public.third", concurrently: true).ordered
          expect(adapter).to receive(:refresh_materialized_view)
            .with("public.fourth_1", concurrently: true).ordered
          expect(adapter).to receive(:refresh_materialized_view)
            .with("public.x_fourth", concurrently: true).ordered
        end

        it "refreshes in the right order when called without namespace" do
          described_class.call(
            :fourth,
            adapter,
            ActiveRecord::Base.connection,
            concurrently: true,
          )
        end

        it "refreshes in the right order when called with namespace" do
          described_class.call(
            "public.fourth",
            adapter,
            ActiveRecord::Base.connection,
            concurrently: true,
          )
        end
      end

      context "view has no dependencies" do
        it "does not raise an error" do
          adapter = Postgres.new

          adapter.create_materialized_view(
            "first",
            "SELECT text 'hi' AS greeting",
          )

          expect {
            described_class.call(:first, adapter, ActiveRecord::Base.connection)
          }.not_to raise_error
        end
      end
    end
  end
end
