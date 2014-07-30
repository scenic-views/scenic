require "spec_helper"

describe Scenic::ActiveRecord::CommandRecorder do
  describe "#create_view" do
    it "records the created view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_view :greetings

      expect(recorder.commands).to eq [[:create_view, [:greetings], nil]]
    end

    it "reverts to drop_view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.revert { recorder.create_view :greetings }

      expect(recorder.commands).to eq [[:drop_view, [:greetings]]]
    end
  end
end
