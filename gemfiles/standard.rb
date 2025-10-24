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
  end

  group :development, :test do
    gem 'rspec', '~> 3.12'

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
    gem 'rspec_junit_formatter'

    platform :mri do
      gem 'timeout-interrupt'
    end
  end
end
