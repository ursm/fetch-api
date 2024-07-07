require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'steep/rake_task'

RSpec::Core::RakeTask.new :spec
Steep::RakeTask.new :steep

task :rbs do
  sh 'bundle exec rbs -I sig validate'
end

task default: %i(spec rbs steep)
