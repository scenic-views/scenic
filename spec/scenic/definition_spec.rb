require "spec_helper"

module Scenic
  describe Definition do
    describe "to_sql" do
      it "returns the content of a view definition" do
        sql_definition = "SELECT text 'Hi' as greeting"
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Definition.new("searches", 1)

        expect(definition.to_sql).to eq sql_definition
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")

        expect do
          Definition.new("searches", 1).to_sql
        end.to raise_error RuntimeError
      end
    end

    describe "path" do
      it "returns a sql file in db/views with padded version and view name" do
        expected = Rails.root.join("db/views/searches_v01.sql")

        definition = Definition.new("searches", 1)

        expect(definition.path).to eq expected
      end

      it "handles schema qualified view names" do
        definition = Definition.new("non_public.searches", 1)
        expected = Rails.root.join("db", "views", "non_public_searches_v01.sql")

        expect(definition.path).to eq expected
      end
    end

    describe "version" do
      it "pads the version number with 0" do
        definition = Definition.new(:_, 1)

        expect(definition.version).to eq 1
      end

      it "doesn't pad more than 2 characters" do
        definition = Definition.new(:_, 15)

        expect(definition.version).to eq 15
      end
    end
  end
end
