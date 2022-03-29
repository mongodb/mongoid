#!/bin/sh

set -e

NAME=mongoid
RELEASE_NAME=mongoid-release
VERSION_REQUIRE=mongoid/version
VERSION_CONSTANT_NAME=Mongoid::VERSION

if ! test -f gem-private_key.pem; then
  echo "gem-private_key.pem missing - cannot release" 1>&2
  exit 1
fi

VERSION=`ruby -Ilib -r$VERSION_REQUIRE -e "puts $VERSION_CONSTANT_NAME"`

echo "Releasing $NAME $VERSION"
echo

for variant in mri; do
  docker build -f release/$variant/Dockerfile -t $RELEASE_NAME-$variant .

  docker kill $RELEASE_NAME-$variant || true
  docker container rm $RELEASE_NAME-$variant || true

  docker run -d --name $RELEASE_NAME-$variant -it $RELEASE_NAME-$variant

  docker exec $RELEASE_NAME-$variant /app/release/$variant/build.sh

  docker cp $RELEASE_NAME-$variant:/app/pkg/$NAME-$VERSION.gem .

  docker kill $RELEASE_NAME-$variant
done

echo
echo Built: $NAME-$VERSION.gem
echo

git tag -a v$VERSION -m "Tagging release: $VERSION"
git push origin v$VERSION

gem push $NAME-$VERSION.gem
