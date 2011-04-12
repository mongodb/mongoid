# -*- encoding: utf-8 -*-
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
  s.summary     = "Elegent Persistance in Ruby for MongoDB."
  s.description = "Mongoid is an ODM (Object Document Mapper) Framework for MongoDB, written in Ruby."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "mongoid"

  s.add_runtime_dependency("activesupport", ["< 3.0.0"])
  s.add_runtime_dependency("durran-validatable", [">= 2.0.1"])
  s.add_runtime_dependency("will_paginate", ["< 2.9"])
  s.add_runtime_dependency("mongo", ["~> 1.3.0"])
  s.add_runtime_dependency("bson", ["~> 1.3.0"])

  s.add_development_dependency(%q<rspec>, ["= 1.3.0"])
  s.add_development_dependency(%q<mocha>, ["= 0.9.8"])

  s.files        = Dir.glob("lib/**/*") + %w(MIT_LICENSE README.rdoc)
  s.require_path = 'lib'
end
