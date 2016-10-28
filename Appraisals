appraise "rails32" do
  gem "activerecord", "~> 3.2.0"
  gem "railties", "~> 3.2.0"
end

appraise "rails40" do
  gem "activerecord", "~> 4.0.0"
  gem "railties", "~> 4.0.0"
end

appraise "rails41" do
  gem "activerecord", "~> 4.1.0"
  gem "railties", "~> 4.1.0"
end

appraise "rails42" do
  gem "activerecord", "~> 4.2.0"
  gem "railties", "~> 4.2.0"
end

if RUBY_VERSION > "2.2.0"
  appraise "rails50" do
    gem "rails", github: "rails/rails"
    gem "rspec-rails", github: "rspec/rspec-rails"
    gem "rspec-support", github: "rspec/rspec-support"
    gem "rspec-core", github: "rspec/rspec-core"
    gem "rspec-mocks", github: "rspec/rspec-mocks"
    gem "rspec-expectations", github: "rspec/rspec-expectations"
    gem "rspec", github: "rspec/rspec"
  end
end
