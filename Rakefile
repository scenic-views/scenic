require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec do
  `cd spec/dummy && rake db:drop db:create`
end
