source "https://rubygems.org"

# Specify your gem's dependencies in scenic.gemspec
gemspec

rails_version = ENV.fetch("RAILS_VERSION", "6.1")

rails_constraint = if rails_version == "master"
  {github: "rails/rails"}
else
  "~> #{rails_version}.0"
end

gem "rails", rails_constraint
gem "sprockets", "< 4.0.0"
gem "pg", "~> 1.1"
