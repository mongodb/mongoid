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

  s.add_runtime_dependency("activemodel", ["~>3.0.0.beta"])
  s.add_runtime_dependency("tzinfo", ["~>0.3.22"])
  s.add_runtime_dependency("will_paginate", ["~>3.0.pre"])
  s.add_runtime_dependency("mongo", ["~>1.0.3"])
  s.add_runtime_dependency("bson", ["~>1.0.3"])

  s.add_development_dependency(%q<rspec>, ["= 2.0.0.beta.12"])
  s.add_development_dependency(%q<mocha>, ["= 0.9.8"])

  s.files        = Dir.glob("lib/**/*") + %w(MIT_LICENSE README.rdoc)
  s.require_path = 'lib'
end
