require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :smoke do
  exec "spec/smoke"
end

namespace :dummy do
  require_relative "spec/dummy/config/application"
  Dummy::Application.load_tasks
end

task default: [:spec, :smoke]
