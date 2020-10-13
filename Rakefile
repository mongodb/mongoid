require "bundler"
require "bundler/gem_tasks"
Bundler.setup

require "rake"
require "rspec/core/rake_task"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "mongoid/version"

tasks = Rake.application.instance_variable_get('@tasks')
tasks['release:do'] = tasks.delete('release')

task :gem => :build
task :build do
  system "gem build mongoid.gemspec"
end

task :install => :build do
  system "sudo gem install mongoid-#{Mongoid::VERSION}.gem"
end

task :release => :build do
  system "git tag -a v#{Mongoid::VERSION} -m 'Tagging #{Mongoid::VERSION}'"
  system "git push --tags"
  system "gem push mongoid-#{Mongoid::VERSION}.gem"
  system "rm mongoid-#{Mongoid::VERSION}.gem"
end

RSpec::Core::RakeTask.new("spec") do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

RSpec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w(--format progress)
  spec.pattern = "spec/**/*_spec.rb"
end

task :default => :spec

namespace :release do
  task :check_private_key do
    unless File.exist?('gem-private_key.pem')
      raise "No private key present, cannot release"
    end
  end
end

task :release => ['release:check_private_key', 'release:do']
