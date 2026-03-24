# rubocop:todo all
def standard_dependencies
  gem 'rake'

  group :development do
    gem 'yard', '>= 0.9.35'

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
    gem 'solargraph', platform: :mri
  end

  group :development, :test do
    gem 'rspec', '~> 3.12'
    gem 'rubocop', '~> 1.86.0'
    gem 'rubocop-performance', '~> 1.26.1'
    gem 'rubocop-rake', '~> 0.7.1'
    gem 'rubocop-rspec', '~> 3.9.0'

    platform :mri do
      gem 'byebug'
      gem 'allocation_stats', require: false
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

  if ENV['FLE'] == 'helper'
    gem 'libmongocrypt-helper', '~> 1.14.0'
  end
end
