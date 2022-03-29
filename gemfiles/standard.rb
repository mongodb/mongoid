def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard'

    # Debugger for VSCode.
    if !ENV['CI'] && RUBY_VERSION < '3.0'
      gem 'debase'
      gem 'ruby-debug-ide'
    end
  end

  group :development, :test do
    gem 'rspec-core', '~> 3.10'
    gem 'byebug'
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
    gem 'timeout-interrupt'
  end
end
