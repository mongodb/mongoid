#!/bin/bash

set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Supported/used environment variables:
#       MONGODB_URI             Set the suggested connection MONGODB_URI (including credentials and topology info)
#       RVM_RUBY                Define the Ruby version to test with, using its RVM identifier.
#                               For example: "ruby-2.3" or "jruby-9.1"

MONGODB_URI=${MONGODB_URI:-}

export CI=evergreen
export JRUBY_OPTS="--server -J-Xms512m -J-Xmx1G"

# Necessary for jruby
# Use toolchain java if it exists
if [ -f /opt/java/jdk8/bin/java ]; then
  export JAVACMD=/opt/java/jdk8/bin/java
  export PATH=$PATH:/opt/java/jdk8/bin
fi
  
# ppc64le has it in a different place
if test -z "$JAVACMD" && [ -f /usr/lib/jvm/java-1.8.0/bin/java ]; then
  export JAVACMD=/usr/lib/jvm/java-1.8.0/bin/java
  export PATH=$PATH:/usr/lib/jvm/java-1.8.0/bin
fi

if [ "$RVM_RUBY" == "ruby-head" ]; then
  # 12.04, 14.04 and 16.04 are good
  wget -O ruby-head.tar.bz2 http://rubies.travis-ci.org/ubuntu/`lsb_release -rs`/x86_64/ruby-head.tar.bz2
  tar xf ruby-head.tar.bz2
  export PATH=`pwd`/ruby-head/bin:`pwd`/ruby-head/lib/ruby/gems/2.6.0/bin:$PATH
  ruby --version
  ruby --version |grep dev
  
  #rvm reinstall $RVM_RUBY
else
  toolchain_url=https://s3.amazonaws.com//mciuploads/mongo-ruby-toolchain/rhel70/07f2c6cf44624721cfc614547de3b2db8fb29919/mongo_ruby_driver_toolchain_rhel70_07f2c6cf44624721cfc614547de3b2db8fb29919_18_07_27_19_35_52.tar.gz
  curl -fL $toolchain_url |tar zxf -
  
  export PATH=`pwd`/rubies/$RVM_RUBY/bin:$PATH

  # Ensure we're using the right ruby
  python - <<EOH
ruby = "${RVM_RUBY}".split("-")[0]
version = "${RVM_RUBY}".split("-")[1]
assert(ruby in "`ruby --version`")
assert(version in "`ruby --version`")
EOH

  echo 'updating rubygems'
  gem update --system

  # ruby-head comes with bundler and gem complains
  # because installing bundler would overwrite the bundler binary
  gem install bundler
fi

echo "We are in `pwd`"

if [ $DRIVER == "master" ]; then
  bundle install --gemfile=gemfiles/driver_master.gemfile
  BUNDLE_GEMFILE=gemfiles/driver_master.gemfile bundle exec rake spec
elif [ $RAILS == "master" ]; then
  bundle install --gemfile=gemfiles/rails_master.gemfile
  BUNDLE_GEMFILE=gemfiles/rails_master.gemfile bundle exec rake spec
else
  bundle install
  bundle exec rake spec
fi
