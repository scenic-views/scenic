require "spec_helper"

module Scenic
  module Adapters
    describe Postgres, "cascade error handling" do
      describe "CascadeUpdateFailedError" do
        it "includes view name and original error in message" do
          original_error = "column 'invalid' does not exist"
          error = Postgres::CascadeUpdateFailedError.new("my_view", original_error)

          expect(error.message).to include("my_view")
          expect(error.message).to include("column 'invalid' does not exist")
          expect(error.message).to include("Failed to update materialized view")
        end

        it "inherits from StandardError" do
          error = Postgres::CascadeUpdateFailedError.new("view", "error")
          
          expect(error).to be_a(StandardError)
        end
      end
    end
  end
end