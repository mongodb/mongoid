source 'https://rubygems.org'
gemspec

gem 'rake'
gem 'actionpack', '~> 5.1'
gem 'activemodel', '~> 5.1'


group :test do
  gem 'benchmark-ips'
  gem 'rspec', '~> 3.7'
end

group :development, :testing do
  platforms :mri do
    if RUBY_VERSION >= '2.0.0'
      gem 'byebug'
    end
  end
end
