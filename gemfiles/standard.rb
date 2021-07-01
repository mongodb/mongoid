def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'
  end

  group :development, :test do
    gem 'rspec-core', '~> 3.9'

    platform :mri do
      gem 'byebug'
    end

    platform :jruby do
      gem 'ruby-debug'
    end
  end

  group :test do
    gem 'timecop'
    gem 'rspec-retry'
    gem 'benchmark-ips'
    gem 'rspec-expectations', '~> 3.9'
    gem 'rspec-mocks-diag', '~> 3.9'
    gem 'fuubar'
    gem 'rfc'
    gem 'childprocess'

    platform :mri do
      gem 'timeout-interrupt'
    end
  end
end
