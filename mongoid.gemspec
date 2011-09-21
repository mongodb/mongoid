# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "mongoid/version"

Gem::Specification.new do |s|
  s.name        = "mongoid"
  s.version     = Mongoid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Durran Jordan"]
  s.email       = ["durran@gmail.com"]
  s.homepage    = "http://mongoid.org"
  s.summary     = "Elegant Persistance in Ruby for MongoDB."
  s.description = "Mongoid is an ODM (Object Document Mapper) Framework for MongoDB, written in Ruby."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "mongoid"

  s.add_dependency("activemodel", ["~> 3.1"])
  s.add_dependency("tzinfo", ["~> 0.3.22"])
  s.add_dependency("mongo", ["~> 1.4"])

  s.add_development_dependency("rdoc", ["~> 3.5.0"])
  s.add_development_dependency("bson_ext", ["~> 1.4"])
  s.add_development_dependency("mocha", ["~> 0.9.12"])
  s.add_development_dependency("rspec", ["~> 2.6"])
  s.add_development_dependency("watchr", ["~> 0.6"])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.require_path = 'lib'
end
