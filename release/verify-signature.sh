#!/bin/bash

set -ex

gem="$1"
if test -z "$gem"; then
  echo "Usage: `basename $0` /path/to/built.gem" 1>&2
  exit 1
fi

gem cert --add gem-public_cert.pem
gem install -P HighSecurity $gem

exit

# The verification below does not work.
# https://github.com/rubygems/rubygems/issues/3680

# https://docs.ruby-lang.org/en/2.7.0/Gem/Security.html

tar xf $gem

# Grab the public key from the gemspec

gem spec $gem cert_chain | \
  ruby -ryaml -e 'puts YAML.load(STDIN)' > actual_public_key.crt

for file in data.tar.gz metadata.tar.gz; do
  # Generate a SHA1 hash of the data.tar.gz

  openssl dgst -sha1 < $file > actual.hash

  # Verify the signature

  openssl rsautl -verify -inkey actual_public_key.crt -certin \
    -in $file.sig > signed.hash

  # Compare your hash to the verified hash

  diff -s actual.hash signed.hash
done
