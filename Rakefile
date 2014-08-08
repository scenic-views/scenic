require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :bats do
  exec "bats spec/bats"
end

task default: [:spec, :bats]
