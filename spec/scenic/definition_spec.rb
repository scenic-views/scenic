require "spec_helper"

module Scenic
  describe Definition do
    describe "to_sql" do
      it "returns the content of a view definition" do
        sql_definition = "SELECT text 'Hi' as greeting"
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Definition.new("searches", 1, nil)

        expect(definition.to_sql).to eq sql_definition
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")

        expect do
          Definition.new("searches", 1, nil).to_sql
        end.to raise_error RuntimeError
      end
    end

    describe "path" do
      context "no custom path" do
        it "returns a sql file in db/views with padded version and view name"  do
          expected = "db/views/searches_v01.sql"

          definition = Definition.new("searches", 1, nil)

          expect(definition.path).to eq expected
        end
      end

      context "with custom path" do
        it "returns a sql file in custom path with padded version and view name"  do
          expected = "my_path/views/searches_v01.sql"

          definition = Definition.new("searches", 1, "my_path")

          expect(definition.path).to eq expected
        end
      end
    end

    describe "full_path" do
      it "joins the path with Rails.root" do
        definition = Definition.new("searches", 15, nil)

        expect(definition.full_path).to eq Rails.root.join(definition.path)
      end
    end

    describe "version" do
      it "pads the version number with 0" do
        definition = Definition.new(:_, 1, nil)

        expect(definition.version).to eq "01"
      end

      it "doesn't pad more than 2 characters" do
        definition = Definition.new(:_, 15, nil)

        expect(definition.version).to eq "15"
      end
    end
  end
end
