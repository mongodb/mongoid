def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'

    platform :mri do
      # Debugger for VSCode.
      if !ENV['CI'] && !ENV['DOCKER'] && RUBY_VERSION < '3.0'
        gem 'debase'
        gem 'ruby-debug-ide'
      end
    end

    # Evergreen configuration generation
    gem 'erubi'
    gem 'tilt'
    gem 'solargraph'
  end

  group :development, :test do
    gem 'rubocop', '~> 1.45.1'
    gem 'rubocop-performance', '~> 1.16.0'
    gem 'rubocop-rails', '~> 2.17.4'
    gem 'rubocop-rake', '~> 0.6.0'
    gem 'rubocop-rspec', '~> 2.18.1'

    platform :mri do
      gem 'byebug'
    end

    platform :jruby do
      gem 'ruby-debug'
    end
  end

  group :test do
    gem 'rspec', '~> 3.10'
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
