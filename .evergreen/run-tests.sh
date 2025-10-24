#!/bin/bash

set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Supported/used environment variables:
#       MONGODB_URI             Set the suggested connection MONGODB_URI (including credentials and topology info)
#       RVM_RUBY                Define the Ruby version to test with, using its RVM identifier.
#                               For example: "ruby-3.0" or "jruby-9.2"

MRSS_ROOT=`dirname "$0"`/../spec/shared

. $MRSS_ROOT/shlib/distro.sh
. $MRSS_ROOT/shlib/set_env.sh
. $MRSS_ROOT/shlib/server.sh
. `dirname "$0"`/functions.sh

arch=`host_distro`

set_fcv
set_env_vars

# Install rbenv and download the requested ruby version
rm -rf ~/.rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
rm -rf ~/.rbenv/versions/
curl --retry 3 -fL http://boxes.10gen.com/build/toolchain-drivers/mongo-ruby-toolchain/library/`host_distro`/$RVM_RUBY.tar.xz |tar -xC $HOME/.rbenv/ -Jf -
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"
export FULL_RUBY_VERSION=$(ls ~/.rbenv/versions | head -n1)
rbenv global $FULL_RUBY_VERSION

export JAVA_HOME=/opt/java/jdk21
export JAVACMD=$JAVA_HOME/bin/java

if test "$FLE" = "helper"; then
  sudo apt-get update && sudo apt-get install -y cmake
fi

if test -n "$APP_TESTS"; then
  set_env_node
fi

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

git config --global --add safe.directory "*"

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
elif test "$DRIVER" = "bson-min"; then
  bundle install --gemfile=gemfiles/bson_min.gemfile
  BUNDLE_GEMFILE=gemfiles/bson_min.gemfile
elif test "$DRIVER" = "bson-master"; then
  bundle install --gemfile=gemfiles/bson_master.gemfile
  BUNDLE_GEMFILE=gemfiles/bson_master.gemfile
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
else
  bundle install
fi

export BUNDLE_GEMFILE

if test "$TOPOLOGY" = "sharded_cluster"; then
  # We assume that sharded cluster has two mongoses
  export MONGODB_URI="mongodb://localhost:27017,localhost:27018/?appName=test-suite&$uri_options"
else
  export MONGODB_URI="mongodb://localhost:27017/?appName=test-suite&$uri_options"
fi

set +e
if test -n "$TEST_CMD"; then
  eval $TEST_CMD
elif test -n "$TEST_I18N_FALLBACKS"; then
  bundle exec rspec spec/integration/i18n_fallbacks_spec.rb \
    spec/mongoid/criteria_spec.rb spec/mongoid/contextual/mongo_spec.rb \
    --format Rfc::Riff --format RspecJunitFormatter --out tmp/rspec.xml
elif test -n "$APP_TESTS"; then
  if test -z "$DOCKER_PRELOAD"; then
    ./spec/shared/bin/install-node
  fi

  bundle exec rspec spec/integration/app_spec.rb --format Rfc::Riff --format RspecJunitFormatter --out tmp/rspec.xml
else
  bundle exec rake ci
fi

test_status=$?
echo "TEST STATUS: ${test_status}"
set -e

if test -f tmp/rspec-all.json; then
  mv tmp/rspec-all.json tmp/rspec.json
fi

exit ${test_status}
