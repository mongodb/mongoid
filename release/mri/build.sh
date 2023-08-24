#!/bin/bash

set -e

rm -f *.lock
rm -f *.gem pkg/*.gem
rake build verify
