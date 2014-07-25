require "spec_helper"

class Search < ActiveRecord::Base; end

describe Scenic::ActiveRecord::SchemaDumper, :db do
  it "dumps a create_view for a view in the database" do
    view_definition = "SELECT 'needle'::text AS haystack"
    Search.connection.create_view :searches, view_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(Search.connection, stream)

    output = stream.string
    expect(output).to include "create_view :searches"
    expect(output).to include view_definition
  end
end
