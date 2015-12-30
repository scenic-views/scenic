require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::Connection do
      describe "supports_materialized_views?" do
        context "supports_materialized_views? was defined on connection" do
          it "uses the previously defined version" do
            base_response = double("response from base connection")
            base_connection = double(
              "Connection",
              supports_materialized_views?: base_response,
            )

            connection = Postgres::Connection.new(base_connection)

            expect(connection.supports_materialized_views?).to be base_response
          end
        end

        context "supports_materialized_views? is not already defined" do
          it "is true if postgres version is at least than 9.3.0" do
            base_connection = double("Connection", postgresql_version: 90300)

            connection = Postgres::Connection.new(base_connection)

            expect(connection.supports_materialized_views?).to be true
          end

          it "is false if postgres version is less than 9.3.0" do
            base_connection = double("Connection", postgresql_version: 90299)

            connection = Postgres::Connection.new(base_connection)

            expect(connection.supports_materialized_views?).to be false
          end
        end
      end

      describe "#postgresql_version" do
        it "uses the public method on the provided connection if defined" do
          base_connection = Class.new do
            def postgresql_version
              123
            end
          end

          connection = Postgres::Connection.new(base_connection.new)

          expect(connection.postgresql_version).to eq 123
        end

        it "uses the protected method if the underlying method is not public" do
          base_connection = Class.new do
            protected

            def postgresql_version
              123
            end
          end

          connection = Postgres::Connection.new(base_connection.new)

          expect(connection.postgresql_version).to eq 123
        end
      end

      describe "#supports_concurrent_refresh" do
        it "is true if postgres version is at least 9.4.0" do
          base_connection = double("Connection", postgresql_version: 90400)

          connection = Postgres::Connection.new(base_connection)

          expect(connection.supports_concurrent_refreshes?).to be true
        end
      end
    end
  end
end
