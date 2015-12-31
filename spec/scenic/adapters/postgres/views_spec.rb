require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::Views, :db do
      it "does not query for materialized views if not supported" do
        connection = ActiveRecord::Base.connection
        allow(connection).to receive(:supports_materialized_views?)
          .and_return(false)
        ActiveRecord::Base.connection.execute(
          "CREATE VIEW greetings AS SELECT text 'hi' AS greeting",
        )
        ActiveRecord::Base.connection.execute(
          "CREATE MATERIALIZED VIEW farewells AS SELECT text 'bye' AS text",
        )

        views = Postgres::Views.new(connection).all

        expect(views.map(&:name)).to eq ["greetings"]
      end
    end
  end
end
