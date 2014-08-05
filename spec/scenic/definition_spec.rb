require "spec_helper"

describe Scenic::Definition do
  describe "to_sql" do
    it "returns the content of a view definition" do
      sql_definition = "SELECT text 'Hi' as greeting"
      allow(File).to receive(:read).and_return(sql_definition)

      definition = Scenic::Definition.new("searches", 1)

      expect(definition.to_sql).to eq sql_definition
    end
  end

  describe "path" do
    it "returns a sql file in db/views with padded version and view name"  do
      expected = "db/views/searches_v01.sql"

      definition = Scenic::Definition.new("searches", 1)

      expect(definition.path).to eq expected
    end
  end

  describe "full_path" do
    it "joins the path with Rails.root" do
      definition = Scenic::Definition.new("searches", 15)

      expect(definition.full_path).to eq Rails.root.join(definition.path)
    end
  end

  describe "version" do
    it "pads the version number with 0" do
      definition = Scenic::Definition.new(:_, 1)

      expect(definition.version).to eq "01"
    end

    it "doesn't pad more than 2 characters" do
      definition = Scenic::Definition.new(:_, 15)

      expect(definition.version).to eq "15"
    end
  end
end
