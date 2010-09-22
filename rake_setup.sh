#!/bin/bash
rvm use ruby-1.8.7@mongoid      || exit $?
bundle                          || exit $?
rvm use ruby-1.9.1@mongoid      || exit $?
bundle                          || exit $?
rvm use ruby-1.9.2-head@mongoid || exit $?
bundle                          || exit $?
