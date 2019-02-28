source 'https://rubygems.org'
gemspec

gem 'rake'
gem 'actionpack', '~> 5.1'
gem 'activemodel', '~> 5.1'

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

group :test do
  gem 'rspec-retry'
  gem 'benchmark-ips'
  gem 'rspec', '~> 3.7'
  gem 'fuubar'
  gem 'rfc'
  platforms :mri do
    gem 'timeout-interrupt'
  end
end

group :development, :testing do
  gem 'yard'
  platforms :mri do
    gem 'byebug'
  end
end
