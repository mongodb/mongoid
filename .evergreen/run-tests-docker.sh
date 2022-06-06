#!/bin/bash

set -e
set -o pipefail

params=
for var in MONGODB_VERSION TOPOLOGY RVM_RUBY \
  SINGLE_MONGOS AUTH SSL APP_TESTS
do
  value="${!var}"
  if test -n "$value"; then
    params="$params $var=${!var}"
  fi
done

if test -f .env.private; then
  params="$params -a .env.private"
  gem install dotenv || gem install --user dotenv
fi

./.evergreen/test-on-docker -p -d $DOCKER_DISTRO $params
