require "spec_helper"

module Scenic
  module Adapters
    describe Postgres::TemporaryName do
      it "generates a temporary name based on a SHA1 hash of the original" do
        name = "my_materialized_view"

        temporary_name = Postgres::TemporaryName.new(name).to_s

        expect(temporary_name).to match(/_scenic_sbs_[0-9a-f]{40}/)
      end

      it "does not overflow the 63 character limit for object names" do
        name = "long_view_name_" * 10

        temporary_name = Postgres::TemporaryName.new(name).to_s

        expect(temporary_name.length).to eq 52
      end
    end
  end
end
