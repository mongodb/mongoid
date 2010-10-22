require "bundler"
Bundler.setup

require "rake"
require "rake/rdoctask"
require "rspec"
require "rspec/core/rake_task"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "mongoid/version"

task :gem => :build
task :build do
  system "gem build mongoid.gemspec"
end

task :install => :build do
  system "sudo gem install mongoid-#{Mongoid::VERSION}.gem"
end

task :release => :build do
  puts "Tagging #{Mongoid::VERSION}..."
  system "git tag -a #{Mongoid::VERSION} -m 'Tagging #{Mongoid::VERSION}'"
  puts "Pushing to Github..."
  system "git push --tags"
  puts "Pushing to rubygems.org..."
  system "gem push mongoid-#{Mongoid::VERSION}.gem"
end

Rspec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

Rspec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w(--format progress)
  spec.pattern = "spec/**/*_spec.rb"
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "mongoid #{Mongoid::VERSION}"
  rdoc.rdoc_files.include("README*")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

task :default => :spec
