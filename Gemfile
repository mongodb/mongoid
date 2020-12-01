source 'https://rubygems.org'
gemspec

gem 'rake'
gem 'actionpack'
gem 'activemodel'

# https://jira.mongodb.org/browse/MONGOID-4614
if RUBY_VERSION < '2.3'
  gem 'i18n', '~> 1.0', '>= 1.1', '< 1.5'
  # nokogiri does not support 2.2 anymore.
  # https://github.com/sparklemotion/nokogiri/issues/1841
  # We are getting it as a transitive dependency
  gem 'nokogiri', '<1.10'
else
  gem 'i18n', '~> 1.0', '>= 1.1'
end

group :development do
  gem 'yard'
end

group :development, :test do
  gem 'rspec-core', '~> 3.7'
end

group :test do
  gem 'rspec-retry'
  gem 'benchmark-ips'
  gem 'rspec-expectations', '~> 3.7', '>= 3.8.4'
  gem 'rspec-mocks-diag', '~> 3.0'
  gem 'fuubar'
  gem 'rfc'
  gem 'childprocess'
  platforms :mri do
    gem 'timeout-interrupt'
    if RUBY_VERSION < '2.3'
      gem 'byebug', '~> 10.0'
    else
      gem 'byebug'
    end
  end
end
