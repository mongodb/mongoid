def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'
  end

  group :development, :test do
    gem 'rspec', '~> 3.10'

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
    gem 'fuubar'
    gem 'rfc'
    gem 'childprocess'

    platform :mri do
      gem 'timeout-interrupt'
    end
  end
end
