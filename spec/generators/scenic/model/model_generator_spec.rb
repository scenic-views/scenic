require "spec_helper"
require "generators/scenic/model/model_generator"

module Scenic::Generators
  describe ModelGenerator, :generator do
    before do
      allow(ViewGenerator).to receive(:new)
        .and_return(
          instance_double("Scenic::Generators::ViewGenerator").as_null_object
        )
    end

    it "invokes the view generator" do
      run_generator ["current_customer"]

      expect(ViewGenerator).to have_received(:new)
    end

    it "creates a migration to create the view" do
      run_generator ["current_customer"]
      model_definition = file("app/models/current_customer.rb")
      expect(model_definition).to exist
    end
  end
end
