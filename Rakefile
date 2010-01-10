require "rubygems"
require "rake"
require "rake/rdoctask"
require "spec/rake/spectask"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "mongoid"
    gem.summary = "ODM framework for MongoDB"
    gem.email = "durran@gmail.com"
    gem.homepage = "http://mongoid.org"
    gem.authors = ["Durran Jordan"]

    gem.add_dependency("activesupport", ">= 2.2.2")
    gem.add_dependency("mongo", ">= 0.18.2")
    gem.add_dependency("durran-validatable", ">= 2.0.1")
    gem.add_dependency("leshill-will_paginate", ">= 2.3.11")

    gem.add_development_dependency("rspec", ">= 1.2.9")
    gem.add_development_dependency("mocha", ">= 0.9.8")
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
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
