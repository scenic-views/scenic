require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :smoke do
  exec "spec/smoke"
end

task default: [:spec, :smoke]
