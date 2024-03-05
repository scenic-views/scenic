source "https://rubygems.org"

# Specify your gem's dependencies in scenic.gemspec
gemspec

rails_version = ENV.fetch("RAILS_VERSION", "7.1")

rails_constraint = if rails_version == "main"
  {github: "rails/rails"}
else
  "~> #{rails_version}.0"
end

gem "activerecord", rails_constraint
gem "railties", rails_constraint
