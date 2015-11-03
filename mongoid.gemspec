# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "mongoid/version"

Gem::Specification.new do |s|
  s.name        = "mongoid"
  s.version     = Mongoid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Durran Jordan"]
  s.email       = ["mongodb-dev@googlegroups.com"]
  s.homepage    = "http://mongoid.org"
  s.summary     = "Elegant Persistence in Ruby for MongoDB."
  s.description = "Mongoid is an ODM (Object Document Mapper) Framework for MongoDB, written in Ruby."
  s.license     = "MIT"

  if File.exists?('gem-private_key.pem')
    s.signing_key     = 'gem-private_key.pem'
    s.cert_chain      = ['gem-public_cert.pem']
  else
    warn "[#{s.name}] Warning: No private key present, creating unsigned gem."
  end

  s.required_ruby_version     = ">= 1.9"
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "mongoid"

  s.add_dependency("activemodel", ["~> 4.0"])
  s.add_dependency("tzinfo", [">= 0.3.37"])
  s.add_dependency("mongo", ["~> 2.1"])
  s.add_dependency("origin", ["~> 2.1"])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.test_files   = Dir.glob("spec/**/*")
  s.require_path = 'lib'
end
