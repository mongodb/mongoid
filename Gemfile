source 'https://rubygems.org'

gemspec

require_relative './gemfiles/standard'

standard_dependencies

gem 'actionpack', '>= 5.1'
gem 'activemodel', '>= 5.1'

i18n_versions = ['~> 1.0', '>= 1.1']
if RUBY_PLATFORM =~ /java/
  # https://github.com/jruby/jruby/issues/6573
  i18n_versions << '< 1.8.8'
end

gem 'i18n', *i18n_versions
