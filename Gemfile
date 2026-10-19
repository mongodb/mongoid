# rubocop:todo all
source 'https://rubygems.org'

gemspec

require_relative './gemfiles/standard'

standard_dependencies

gem 'actionpack'
gem 'activemodel'

i18n_versions = ['~> 1.0', '>= 1.1']
if RUBY_PLATFORM =~ /java/
  # https://github.com/jruby/jruby/issues/6573
  i18n_versions << '< 1.8.8'
end

if RUBY_VERSION < '3.2'
  # 1.15.0 uses Fiber[:foo] syntax, which breaks on Ruby 3.1
  i18n_versions << '< 1.15.0'
end

gem 'i18n', *i18n_versions

# :windows is a Bundler alias for every Windows platform, added in Bundler 2.5.
# Older Bundlers have to name them, and naming only :mswin would miss the mingw
# variants that Windows MRI actually reports.
bundler_version = Gem::Version.new(Bundler::VERSION)

tzinfo_platforms = %i[ jruby ]
tzinfo_platforms += if bundler_version >= Gem::Version.new('2.5')
                      %i[ windows ]
                    else
                      %i[ mswin mswin64 mingw x64_mingw ]
                    end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: tzinfo_platforms

gem 'ostruct' if RUBY_VERSION >= '4.0'
