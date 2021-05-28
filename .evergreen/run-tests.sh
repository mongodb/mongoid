#!/bin/bash

set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Supported/used environment variables:
#       MONGODB_URI             Set the suggested connection MONGODB_URI (including credentials and topology info)
#       RVM_RUBY                Define the Ruby version to test with, using its RVM identifier.
#                               For example: "ruby-3.0" or "jruby-9.2"

. `dirname "$0"`/../spec/shared/shlib/distro.sh
. `dirname "$0"`/../spec/shared/shlib/set_env.sh
. `dirname "$0"`/../spec/shared/shlib/server.sh
. `dirname "$0"`/functions.sh

arch=`host_distro`

set_fcv
set_env_vars
set_env_ruby

prepare_server $arch

install_mlaunch_virtualenv

# Launching mongod under $MONGO_ORCHESTRATION_HOME
# makes its log available through log collecting machinery

export dbdir="$MONGO_ORCHESTRATION_HOME"/db
mkdir -p "$dbdir"

calculate_server_args
launch_server "$dbdir"

uri_options="$URI_OPTIONS"

which bundle
bundle --version

if echo $RVM_RUBY |grep -q jruby && test "$DRIVER" = master-jruby; then
  # See https://jira.mongodb.org/browse/RUBY-2156
  git clone https://github.com/mongodb/bson-ruby
  (cd bson-ruby &&
    bundle install &&
    rake compile &&
    gem build *.gemspec &&
    gem install *.gem)
fi

if test "$DRIVER" = "master"; then
  bundle install --gemfile=gemfiles/driver_master.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_master.gemfile
elif test "$DRIVER" = "stable"; then
  bundle install --gemfile=gemfiles/driver_stable.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_stable.gemfile
elif test "$DRIVER" = "oldstable"; then
  bundle install --gemfile=gemfiles/driver_oldstable.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_oldstable.gemfile
elif test "$DRIVER" = "min"; then
  bundle install --gemfile=gemfiles/driver_min.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_min.gemfile
elif test "$DRIVER" = "stable-jruby"; then
  bundle install --gemfile=gemfiles/driver_stable_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_stable_jruby.gemfile
elif test "$DRIVER" = "oldstable-jruby"; then
  bundle install --gemfile=gemfiles/driver_oldstable_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_oldstable_jruby.gemfile
elif test "$DRIVER" = "min-jruby"; then
  bundle install --gemfile=gemfiles/driver_min_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_min_jruby.gemfile
elif test "$RAILS" = "master-jruby"; then
  bundle install --gemfile=gemfiles/rails-master_jruby.gemfile
  BUNDLE_GEMFILE=gemfiles/rails-master_jruby.gemfile
elif test -n "$RAILS" && test "$RAILS" != 6.1; then
  bundle install --gemfile=gemfiles/rails-"$RAILS".gemfile
  BUNDLE_GEMFILE=gemfiles/rails-"$RAILS".gemfile
elif test "$I18N" = "1.0"; then
  bundle install --gemfile=gemfiles/i18n-1.0.gemfile
  BUNDLE_GEMFILE=gemfiles/i18n-1.0.gemfile
else
  bundle install
fi

export BUNDLE_GEMFILE

export MONGODB_URI="mongodb://localhost:27017/?appName=test-suite&$uri_options"

set +e
if test -n "$TEST_CMD"; then
  eval $TEST_CMD
elif test -n "$TEST_I18N_FALLBACKS"; then
  bundle exec rspec spec/integration/i18n_fallbacks_spec.rb
elif test -n "$APP_TESTS"; then
  # Need recent node for rails
  export N_PREFIX=$HOME/.n
  curl -o $HOME/n --retry 3 https://raw.githubusercontent.com/tj/n/master/bin/n
  bash $HOME/n stable
  export PATH=$HOME/.n/bin:$PATH
  npm -g install yarn
  
  bundle exec rspec spec/integration/app_spec.rb
else
  bundle exec rake ci
fi

test_status=$?
echo "TEST STATUS: ${test_status}"
set -e

if test -f tmp/rspec-all.json; then
  mv tmp/rspec-all.json tmp/rspec.json
fi

python -m mtools.mlaunch.mlaunch stop --dir "$dbdir"

exit ${test_status}
