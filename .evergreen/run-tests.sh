#!/bin/bash

set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Supported/used environment variables:
#       MONGODB_URI             Set the suggested connection MONGODB_URI (including credentials and topology info)
#       RVM_RUBY                Define the Ruby version to test with, using its RVM identifier.
#                               For example: "ruby-2.3" or "jruby-9.1"

. `dirname "$0"`/functions.sh

set_fcv
set_env_vars

setup_ruby

which bundle
bundle --version

if test "$DRIVER" = "master"; then
  bundle install --gemfile=gemfiles/driver_master.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_master.gemfile bundle exec rake spec
elif test "$DRIVER" = "stable"; then
  bundle install --gemfile=gemfiles/driver_stable.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_stable.gemfile bundle exec rake spec
elif test "$DRIVER" = "oldstable"; then
  bundle install --gemfile=gemfiles/driver_oldstable.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_oldstable.gemfile bundle exec rake spec
elif test "$DRIVER" = "min"; then
  bundle install --gemfile=gemfiles/driver_min.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_min.gemfile bundle exec rake spec
elif test "$DRIVER" = "stable-jruby"; then
  bundle install --gemfile=gemfiles/driver_stable_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_stable_jruby.gemfile bundle exec rake spec
elif test "$DRIVER" = "oldstable-jruby"; then
  bundle install --gemfile=gemfiles/driver_oldstable_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_oldstable_jruby.gemfile bundle exec rake spec
elif test "$DRIVER" = "min-jruby"; then
  bundle install --gemfile=gemfiles/driver_min_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_min_jruby.gemfile bundle exec rake spec
elif test "$RAILS" = "master-jruby"; then
  bundle install --gemfile=gemfiles/rails_master_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/rails_master_jruby.gemfile bundle exec rake spec
elif test -n "$RAILS"; then
  bundle install --gemfile=gemfiles/rails_"$RAILS".gemfile
  BUNDLE_GEMFILE=gemfiles/rails_"$RAILS".gemfile bundle exec rake spec
elif test "$I18N" = "1.0"; then
  bundle install --gemfile=gemfiles/i18n-1.0.gemfile
  BUNDLE_GEMFILE=gemfiles/i18n-1.0.gemfile bundle exec rake spec
else
  bundle install
  bundle exec rake spec
fi
