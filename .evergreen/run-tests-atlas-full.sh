#!/bin/bash

set -ex

. `dirname "$0"`/../spec/shared/shlib/distro.sh
. `dirname "$0"`/../spec/shared/shlib/set_env.sh
. `dirname "$0"`/functions.sh

set_env_vars

# Install rbenv and download the requested ruby version
arch=`host_distro`
rm -rf ~/.rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
rm -rf ~/.rbenv/versions/
curl --retry 3 -fL http://boxes.10gen.com/build/toolchain-drivers/mongo-ruby-toolchain/library/`host_distro`/$RVM_RUBY.tar.xz |tar -xC $HOME/.rbenv/ -Jf -
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"
export FULL_RUBY_VERSION=$(ls ~/.rbenv/versions | head -n1)
rbenv global $FULL_RUBY_VERSION

export BUNDLE_GEMFILE=gemfiles/driver_master.gemfile
bundle install

ATLAS_URI=$MONGODB_URI \
  EXAMPLE_TIMEOUT=600 \
  bundle exec rspec -fd spec/mongoid/search_indexable_spec.rb \
  --format Rfc::Riff --format RspecJunitFormatter --out tmp/rspec.xml

test_status=$?

kill_jruby

exit ${test_status}
