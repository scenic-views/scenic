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

  describe "#drop_view" do
    it "records the dropped view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.drop_view :users

      expect(recorder.commands).to eq [[:drop_view, [:users], nil]]
    end

    it "reverts to create_view with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, { revert_to_version: 1 }]

      recorder.revert { recorder.drop_view(*args) }

      expect(recorder.commands).to eq [[:create_view, args[0]]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, { another_argument: 1 }]

      expect { recorder.revert { recorder.drop_view(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end
end
