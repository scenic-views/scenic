appraise "rails52" do
  gem "activerecord", "~> 5.2.0"
  gem "railties", "~> 5.2.0"
end

if RUBY_VERSION >= "2.5.0"
  appraise "rails60" do
    gem "activerecord", "~> 6.0.0"
    gem "railties", "~> 6.0.0"
  end

  appraise "rails-edge" do
    gem "rails", git: "https://github.com/rails/rails"
    gem "arel", git: "https://github.com/rails/arel"
  end
end
