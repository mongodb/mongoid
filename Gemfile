source 'https://rubygems.org'
gemspec

gem 'rake'
gem 'actionpack'
gem 'activemodel'

gem 'i18n', '~> 1.0', '>= 1.1'

group :development do
  gem 'yard'
end

group :test do
  gem 'rspec-retry'
  gem 'benchmark-ips'
  gem 'rspec-core', '~> 3.7'
  gem 'rspec-expectations', '~> 3.7', '>= 3.8.4'
  gem 'rspec-mocks-diag', '~> 3.0'
  gem 'fuubar'
  gem 'rfc'
  platforms :mri do
    gem 'timeout-interrupt'
    gem 'byebug'
  end
end
