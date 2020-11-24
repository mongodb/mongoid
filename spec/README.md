# Running Mongoid Tests

## Quick Start

The test suite requires shared tooling that is stored in a separate repository
and is referenced as a submodule. After checking out the desired driver
branch, check out the matching submodules:

    git submodule init
    git submodule update

Spin up a MongoDB deployment against which to run the Mongoid specs.
Mongoid specs support a variety of MongoDB topologies, but the simplest is
a single MongoDB instance:

    # Launch mongod in one terminal
    mkdir /tmp/mdb
    mongod --dbpath /tmp/mdb

Run the test suite in a separate terminal:

    rake


## Caveats

### "Too many open files" error

On MacOS, you may encounter a "Too many open files" error on the MongoDB server
when running the tests. If this happens, stop the server, run the command
`ulimit -n 10000` in the same terminal session as the server, and restart
the server. This will increase the number of files that can be opened.
Then, re-run the tests.
