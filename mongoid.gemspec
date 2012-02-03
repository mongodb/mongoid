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
  s.add_dependency("moped", ["~> 0.1"])
  s.add_dependency("origin", ["~> 1.0.0.beta"])

  s.add_development_dependency("rdoc", ["~> 3.5.0"])
  s.add_development_dependency("mocha", ["~> 0.10"])
  s.add_development_dependency("rspec", ["~> 2.9"])
  s.add_development_dependency("guard-rspec", ["~> 0.6"])
  s.add_development_dependency("ammeter", ["~> 0.2"])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.require_path = 'lib'
end
