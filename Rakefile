require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default do
  Rake::Task[:spec].execute
  `cd spec/dummy && rake db:drop db:create`
end
