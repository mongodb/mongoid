require "rake"
require "rake/rdoctask"
require "rspec"
require "rspec/core/rake_task"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "mongoid/version"

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
  puts "Pushing to Gemcutter..."
  system "gem push mongoid-#{Mongoid::VERSION}.gem"
end

Rspec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

Rake::RDocTask.new do |rdoc|
  if File.exist?("VERSION.yml")
    config = File.read("VERSION")
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "mongoid #{version}"
  rdoc.rdoc_files.include("README*")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

namespace :spec do
  # runs the specs with both MONGOID_USE_OBJECT_IDS setting to both true and false
  task :all do
    puts "Running Mongoid tests with MONGOID_USE_OBJECT_IDS as \"true\""
    ENV["MONGOID_USE_OBJECT_IDS"] = "true"
    Rake::Task["spec"].invoke

    puts "Running Mongoid tests with MONGOID_USE_OBJECT_IDS as \"false\""
    ENV["MONGOID_USE_OBJECT_IDS"] = "false"
    Rake::Task["spec"].invoke
  end
end

task :default => ["spec:all"]
