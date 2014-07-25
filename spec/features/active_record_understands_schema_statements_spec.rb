require "spec_helper"
require "dummy/db/migrate/1_create_views"

describe "active record understands schema statements", type: :feature do
  it "can run migrations that create views" do
    expect { run_migrations }.not_to raise_error
  end

  def run_migrations
    silence_stream(STDOUT) do
      CreateViews.migrate(:up)
    end
  end
end
