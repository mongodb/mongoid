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
    gem 'rspec-core', '~> 3.10'

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
    gem 'rspec', '~> 3.12'
    gem 'fuubar'
    gem 'rfc'
    gem 'childprocess'
    gem 'puma' # for app tests

    # to fix problem with modern net-imap requiring more modern ruby, on
    # evergreen
    if RUBY_VERSION < '2.7.3'
      gem 'net-imap', '=0.3.7'

    elsif RUBY_VERSION < '3.1'
      gem 'net-imap', '=0.4.18'
    end

    platform :mri do
      gem 'timeout-interrupt'
    end
  end
end
