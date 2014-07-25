require "spec_helper"

class View < ActiveRecord::Base
end

describe Scenic::ActiveRecord::Statements, :db do
  describe "create_view" do
    it "creates a view from a file" do
      with_view_definition :views, 1, "SELECT text 'Hello World' AS hello" do
        View.connection.create_view :views

        expect(View.all.pluck(:hello)).to eq ["Hello World"]
      end
    end

    it "creates a view from a specific version" do
      with_view_definition :views, 15, "SELECT text 'Hello Earth East 15' AS hello" do
        View.connection.create_view :views, version: 15

        expect(View.all.pluck(:hello)).to eq ["Hello Earth East 15"]
      end
    end
  end

  describe "drop_view" do
    it "removes a view from the database" do
      with_view_definition :things, 1, "SELECT text 'Hi' AS greeting" do
        View.connection.create_view :things

        View.connection.drop_view :things

        expect(views).not_to include "things"
      end
    end
  end

  describe "update_view" do
    it "updates an existing view in the database" do
      with_view_definition :views, 1, "SELECT text 'Hi' AS greeting" do
        View.connection.create_view :views
        with_view_definition :views, 2, "SELECT text 'Hello' AS greeting" do
          View.connection.update_view :views, version: 2

          expect(View.all.pluck(:greeting)).to eq ['Hello']
        end
      end
    end

    it "raises an error if not supplied a version" do
      expect { View.connection.update_view :views }
        .to raise_error(ArgumentError, /version is required/)
    end

    it "raises an error if the view to be updated does not exist" do
      with_view_definition :views, 2, "SELECT text 'Hi' as greeting" do
        expect { View.connection.update_view :views, version: 2 }
          .to raise_error(ActiveRecord::StatementInvalid, /does not exist/)
      end
    end
  end

  def views
    ActiveRecord::Base.connection
      .execute("SELECT table_name FROM INFORMATION_SCHEMA.views")
      .map(&:values).flatten
  end
end
