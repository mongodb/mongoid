# encoding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "mongoid/version"

Gem::Specification.new do |s|
  s.name        = "mongoid"
  s.version     = Mongoid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["The MongoDB Ruby Team"]
  s.email       = "dbx-ruby@mongodb.com"
  s.homepage    = "https://mongoid.org"
  s.summary     = "Elegant Persistence in Ruby for MongoDB."
  s.description = "Mongoid is an ODM (Object Document Mapper) Framework for MongoDB, written in Ruby."
  s.license     = "MIT"

  s.metadata = {
    'bug_tracker_uri' => 'https://jira.mongodb.org/projects/MONGOID',
    'changelog_uri' => 'https://github.com/mongodb/mongoid/releases',
    'documentation_uri' => 'https://docs.mongodb.com/mongoid/',
    'homepage_uri' => 'https://mongoid.org/',
    'source_code_uri' => 'https://github.com/mongodb/mongoid',
  }

  if File.exist?('gem-private_key.pem')
    s.signing_key = 'gem-private_key.pem'
    s.cert_chain = ['gem-public_cert.pem']
  else
    warn "[#{s.name}] Warning: No private key present, creating unsigned gem."
  end

  s.required_ruby_version     = ">= 2.3"
  s.required_rubygems_version = ">= 1.3.6"

  if RUBY_VERSION.start_with?('2.')
    s.add_dependency("activemodel", [">=5.1", "<6.2"])
  elsif RUBY_VERSION.start_with?('3.')
    s.add_dependency("activemodel", [">=6.0", "<6.2"])
  end
  s.add_dependency("mongo", ['>=2.7.0', '<3.0.0'])
  # Using this gem is recommended for handling argument delegation issues,
  # especially if support for 2.6 or prior is required.
  # See https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/#delegation
  #
  # We have a bunch of complex delegation logic, including various method_missngs.
  # If we try to fix them "right", it will add too much logic. We will have to
  # handle different Ruby versions (including minor ones, Ruby 2.6 and 2.7
  # behave differently), hash key types (strings vs symbols), ways of passing
  # arguments (with curly braces vs without ones).
  #
  # Therefore, usage of this gem looks like a reasonable solution at the moment.
  s.add_dependency("ruby2_keywords", "~> 0.0.5")

  s.add_development_dependency("bson", ['>=4.9.4', '<5.0.0'])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.test_files   = Dir.glob("spec/**/*")
  s.require_path = 'lib'
end
