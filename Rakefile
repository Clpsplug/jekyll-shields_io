require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

task default: [:test, "standard"]

RSpec::Core::RakeTask.new(:spec)

task test: [:spec]
