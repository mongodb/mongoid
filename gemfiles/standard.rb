def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'
  end

  group :development, :test do
    if RUBY_VERSION.start_with?('3.')
      # Get back to rspec-core after the following is fixed:
      # https://jira.mongodb.org/browse/MONGOID-5117
      gem 'rspec', '~> 3.10'
    elsif RUBY_VERSION.start_with?('2.')
      gem 'rspec-core', '~> 3.7'
    end

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
    if RUBY_VERSION.start_with?('2.')
      # Bring the dependencies back after the following is fixed:
      # https://jira.mongodb.org/browse/MONGOID-5117
      gem 'rspec-expectations', '~> 3.7', '>= 3.8.4'
      gem 'rspec-mocks-diag', '~> 3.0'
    end
    gem 'fuubar'
    gem 'rfc'
    gem 'childprocess'

    platform :mri do
      gem 'timeout-interrupt'
    end
  end
end
