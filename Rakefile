require "rubygems"
require "rake"
require "rake/rdoctask"
require "spec/rake/spectask"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "mongoid/version"

task :build do
  system "gem build mongoid.gemspec"
end

task :install => :build do
  system "gem install mongoid-#{Mongoid::VERSION}.gem"
end

task :release => :build do
  system "gem push mongoid-#{Mongoid::VERSION}"
end

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
  spec.spec_opts = ["--options", "spec/spec.opts"]
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << "lib" << "spec"
  spec.pattern = "spec/**/*_spec.rb"
  spec.spec_opts = ["--options", "spec/spec.opts"]
  spec.rcov = true
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

task :default => ["spec"]
