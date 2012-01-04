require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

task :tag do
  sh "git tag v#{Buster::VERSION}"
end
