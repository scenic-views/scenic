if RUBY_VERSION < "2.4.0"
  appraise "rails40" do
    gem "activerecord", "~> 4.0.0"
    gem "railties", "~> 4.0.0"
  end

  appraise "rails41" do
    gem "activerecord", "~> 4.1.0"
    gem "railties", "~> 4.1.0"
  end
end

appraise "rails42" do
  gem "activerecord", "~> 4.2.0"
  gem "railties", "~> 4.2.0"
end

if RUBY_VERSION > "2.2.0"
  appraise "rails50" do
    gem "activerecord", "~> 5.0.0"
    gem "railties", "~> 5.0.0"
  end

  appraise "rails51" do
    gem "activerecord", "~> 5.1.0"
    gem "railties", "~> 5.1.0"
  end

  appraise "rails-edge" do
    gem "rails", git: "https://github.com/rails/rails"
    gem "arel", git: "https://github.com/rails/arel"
  end
end
