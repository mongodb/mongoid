source 'https://rubygems.org'
gemspec

gem 'rake'
gem 'actionpack', '~> 5.1'
gem 'activemodel', '~> 5.1'


group :test do
  gem 'rspec-retry'
  gem 'benchmark-ips'
  gem 'rspec', '~> 3.7'
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
