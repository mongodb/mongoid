#!/bin/sh
# Download the private "latest" server and crypt_shared. Runs with AWS
# credentials; keep xtrace off so they are not logged.
set -eu

umask 077
staging="$HOME/mongodb-latest"
rm -rf "$staging"
mkdir -p "$staging/server" "$staging/lib"

mongodl="$DRIVERS_TOOLS/.evergreen/mongodl"

run_mongodl() {
  name=$1
  shift
  if ! output=$("$mongodl" "$@" 2>&1); then
    echo "Private S3 download failed for $name (output suppressed)." >&2
    return 1
  fi
  case "$output" in
    *FALLBACK:*)
      echo "Private S3 download fell back to the public host for $name; refusing." >&2
      return 1
      ;;
  esac
}

run_mongodl archive --out "$staging/server" --cache-dir "$DRIVERS_TOOLS/.local/cache" \
  --retries 5 --version latest --strip-path-components 2 --component archive
run_mongodl crypt_shared --out "$staging/lib" --cache-dir "$DRIVERS_TOOLS/.local/cache" \
  --retries 5 --version latest --strip-path-components 1 --component crypt_shared

test -x "$staging/server/mongod"
test -f "$staging/lib/mongo_crypt_v1.so"
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

{
  echo "MONGODB_LATEST_BINARIES: \"$staging/server\""
  echo "MONGODB_LATEST_CRYPT_SHARED: \"$staging/lib/mongo_crypt_v1.so\""
} > latest-mongodb-expansion.yml
