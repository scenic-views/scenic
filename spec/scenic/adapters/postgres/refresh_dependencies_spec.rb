require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::RefreshDependencies, :db do
      let(:adapter) { Postgres.new }

      context 'when the view has dependencies' do
        before do
          adapter.create_materialized_view(
            "first",
            "SELECT text 'hi' AS greeting",
          )

          adapter.create_materialized_view(
            "second",
            "SELECT * from first",
          )

          adapter.create_materialized_view(
            "third",
            "SELECT * from first UNION SELECT * from second",
          )

          adapter.create_materialized_view(
            "fourth_staging",
            "SELECT * from third",
          )

          adapter.create_materialized_view(
            "more_fourth",
            "SELECT * from fourth_staging",
          )

          adapter.create_materialized_view(
            "fourth",
            "SELECT * from more_fourth UNION SELECT * from fourth_staging",
          )

          expect(adapter).to receive(:refresh_materialized_view).
            with("public.first").ordered

          expect(adapter).to receive(:refresh_materialized_view).
            with("public.second").ordered

          expect(adapter).to receive(:refresh_materialized_view).
            with("public.third").ordered

          expect(adapter).to receive(:refresh_materialized_view).
            with("public.fourth_staging").ordered

          expect(adapter).to receive(:refresh_materialized_view).
            with("public.more_fourth").ordered
        end

        it 'refreshes dependencies in the correct order when called without a namespace' do
          described_class.call(:fourth, adapter, ActiveRecord::Base.connection)
        end

        it 'refreshes dependencies in the correct order when called with a namespace' do
          described_class.call(:'public.fourth', adapter, ActiveRecord::Base.connection)
        end
      end

      context 'when the view does not have dependencies' do
        it "does not raise an error" do
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
