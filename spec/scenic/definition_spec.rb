require "spec_helper"

module Scenic
  describe Definition do
    describe "to_sql" do
      it "returns the content of a view definition" do
        sql_definition = "SELECT text 'Hi' as greeting"

        with_fixtures do
          definition = Definition.new("searches", 1)

          expect(definition.to_sql).to eq sql_definition
        end
      end

      it "raises an error if the file is empty" do
        definition = Definition.new("empty_view", 1)

        with_fixtures do
          expect do
            definition.to_sql
          end.to raise_error RuntimeError
        end
      end
    end

    describe "find_definition" do
      it "finds definitions in Rails.root db/views" do
        definition = Definition.new("search_results", 1)

        expect(definition.find_definition).to be
      end

      it "raises an error if file cant be found" do
        definition = Definition.new("searches", 1)

        expect {
          definition.find_definition
        }.to raise_error RuntimeError, /Unable to locate searches_v01.sql/
      end

      it "finds definintions in Rails db/views path" do
        with_fixtures do
          definition = Definition.new("empty_view", 1)

          expect(definition.find_definition).to be
        end
      end
    end

    describe "path" do
      it "returns a sql file in db/views with padded version and view name"  do
        expected = "db/views/searches_v01.sql"

        definition = Definition.new("searches", 1)

        expect(definition.path).to eq expected
      end
    end

    describe "full_path" do
      it "joins the path with Rails.root" do
        definition = Definition.new("searches", 15)

        expect(definition.full_path).to eq Rails.root.join(definition.path)
      end
    end

    describe "version" do
      it "pads the version number with 0" do
        definition = Definition.new(:_, 1)

        expect(definition.version).to eq "01"
      end

      it "doesn't pad more than 2 characters" do
        definition = Definition.new(:_, 15)

        expect(definition.version).to eq "15"
      end
    end

    def with_fixtures
      original = Rails.application.config.paths["db/views"].to_a
      Rails.application.config.paths["db/views"] << File.expand_path("../../fixtures/db_views", __FILE__)
      yield
    ensure
      Rails.application.config.paths["db/views"] = original
    end
  end
end
