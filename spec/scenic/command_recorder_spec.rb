require "spec_helper"

describe Scenic::CommandRecorder do
  describe "#create_view" do
    it "records the created view" do
      recorder.create_view :greetings

      expect(recorder.commands).to eq [[:create_view, [:greetings], nil]]
    end

    it "reverts to drop_view when not passed a version" do
      recorder.revert { recorder.create_view :greetings }

      expect(recorder.commands).to eq [[:drop_view, [:greetings]]]
    end

    it "reverts to drop_view when passed a version" do
      recorder.revert { recorder.create_view :greetings, version: 2 }

      expect(recorder.commands).to eq [[:drop_view, [:greetings]]]
    end

    it "reverts materialized views appropriately" do
      recorder.revert { recorder.create_view :greetings, materialized: true }

      expect(recorder.commands).to eq [
        [:drop_view, [:greetings, materialized: true]],
      ]
    end
  end

  describe "#drop_view" do
    it "records the dropped view" do
      recorder.drop_view :users

      expect(recorder.commands).to eq [[:drop_view, [:users], nil]]
    end

    it "reverts to create_view with specified revert_to_version" do
      args = [:users, { revert_to_version: 3 }]
      revert_args = [:users, { version: 3 }]

      recorder.revert { recorder.drop_view(*args) }

      expect(recorder.commands).to eq [[:create_view, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { another_argument: 1 }]

      expect { recorder.revert { recorder.drop_view(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_view" do
    it "records the updated view" do
      args = [:users, { version: 2 }]

      recorder.update_view(*args)

      expect(recorder.commands).to eq [[:update_view, args, nil]]
    end

    it "reverts to update_view with the specified revert_to_version" do
      args = [:users, { version: 2, revert_to_version: 1 }]
      revert_args = [:users, { version: 1 }]

      recorder.revert { recorder.update_view(*args) }

      expect(recorder.commands).to eq [[:update_view, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.update_view(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#replace_view" do
    it "records the replaced view" do
      args = [:users, { version: 2 }]

      recorder.replace_view(*args)

      expect(recorder.commands).to eq [[:replace_view, args, nil]]
    end

    it "reverts to replace_view with the specified revert_to_version" do
      args = [:users, { version: 2, revert_to_version: 1 }]
      revert_args = [:users, { version: 1 }]

      recorder.revert { recorder.replace_view(*args) }

      expect(recorder.commands).to eq [[:replace_view, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      args = [:users, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.replace_view(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  def recorder
    @recorder ||= ActiveRecord::Migration::CommandRecorder.new
  end
end
