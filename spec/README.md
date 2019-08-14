# Running Mongoid Tests

## Overview
### Quick Start
Spin up a MongoDB deployment against which to run the Mongoid specs. Mongoid specs support a variety of MongoDB topologies, but the simplest is a single MongoDB instance:

    # Launch mongod in one terminal
    mkdir /tmp/mdb
    mongod --dbpath /tmp/mdb

Run the test suite in a separate terminal:

    rake


## Caveats
### "Too many open files" error
On MacOS, you may encounter a "Too many open files" error when running the tests. If this happens, run the command `ulimit -n 10000` and then re-run the tests.