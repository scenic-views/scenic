require "spec_helper"

module Scenic::CommandRecorder
  describe StatementArguments do
    describe "#view" do
      it "is the view name" do
        raw_args = [:spaceships, { foo: :bar }]
        args = StatementArguments.new(raw_args)

        expect(args.view).to eq :spaceships
      end
    end

    describe "#revert_to_version" do
      it "is the revert_to_version from the keyword arguments" do
        raw_args = [:spaceships, { revert_to_version: 42 }]
        args = StatementArguments.new(raw_args)

        expect(args.revert_to_version).to eq 42
      end

      it "is nil if the revert_to_version was not supplied" do
        raw_args = [:spaceships, { foo: :bar }]
        args = StatementArguments.new(raw_args)

        expect(args.revert_to_version).to be nil
      end
    end

    describe "#invert_version" do
      it "returns object with version set to revert_to_version" do
        raw_args = [:meatballs, { version: 42, revert_to_version: 15 }]

        inverted_args = StatementArguments.new(raw_args).invert_version

        expect(inverted_args.version).to eq 15
        expect(inverted_args.revert_to_version).to be nil
      end
    end
  end
end
