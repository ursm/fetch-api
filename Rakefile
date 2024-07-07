require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec

namespace :rbs do
  task :validate do
    sh 'bundle exec rbs -I sig validate'
  end
end

namespace :steep do
  task :check do
    sh 'bundle exec steep check'
  end
end

task default: %i(spec rbs:validate steep:check)
