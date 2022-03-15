def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'

    platform :mri do
      # Debugger for VSCode.
      # 2.5 is too old for debase, 3.1 is too new as of March 2022
      if RUBY_VERSION >= '2.6' && RUBY_VERSION < '3.1'
        gem 'debase'
        gem 'ruby-debug-ide'
      end
    end
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
    gem 'rspec-expectations', '~> 3.7', '>= 3.8.4'
    gem 'rspec-mocks-diag', '~> 3.0'
    gem 'fuubar'
    gem 'rfc'
    gem 'childprocess'

    platform :mri do
      gem 'timeout-interrupt'
    end
  end
end
