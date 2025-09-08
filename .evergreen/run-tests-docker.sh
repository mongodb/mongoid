#!/bin/bash

set -e
set -o pipefail

if test -z "$DOCKER_DISTRO"; then
  echo "DOCKER_DISTRO not set" 1>&2
  exit 2
fi

params=
for var in MONGODB_VERSION TOPOLOGY RVM_RUBY \
  SINGLE_MONGOS AUTH SSL APP_TESTS FLE RAILS DRIVER TEST_I18N_FALLBACKS
do
  value="${!var}"
  if test -n "$value"; then
    params="$params $var=${!var}"
  else
    echo "$var not set"
  fi
done

if test -f .env.private; then
  params="$params -a .env.private"
  gem install dotenv || gem install --user dotenv
fi

./.evergreen/test-on-docker -p -d "$DOCKER_DISTRO" $params
