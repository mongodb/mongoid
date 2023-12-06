# frozen_string_literal: true
# rubocop:todo all

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
    'documentation_uri' => 'https://www.mongodb.com/docs/mongoid/',
    'homepage_uri' => 'https://mongoid.org/',
    'source_code_uri' => 'https://github.com/mongodb/mongoid',
  }

  if File.exist?('gem-private_key.pem')
    s.signing_key = 'gem-private_key.pem'
    s.cert_chain = ['gem-public_cert.pem']
  else
    warn "[#{s.name}] Warning: No private key present, creating unsigned gem."
  end

  s.add_dependency "mongoid-odm"
  s.add_dependency "railsmdb"

  s.files = %w(CHANGELOG.md LICENSE README.md)
end
