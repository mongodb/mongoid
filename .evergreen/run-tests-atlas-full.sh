#!/bin/bash

set -ex

. `dirname "$0"`/../spec/shared/shlib/distro.sh
. `dirname "$0"`/../spec/shared/shlib/set_env.sh
. `dirname "$0"`/functions.sh

set_env_vars
set_env_python
set_env_ruby

export BUNDLE_GEMFILE=gemfiles/driver_master.gemfile
bundle install

ATLAS_URI=$MONGODB_URI \
  EXAMPLE_TIMEOUT=600 \
  bundle exec rspec -fd spec/mongoid/search_indexable_spec.rb

test_status=$?

kill_jruby

exit ${test_status}
