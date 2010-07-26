#!/bin/bash
rvm use ruby-1.8.7@mongoid      || exit $?
bundle install                  || exit $?
rvm use ruby-1.9.1@mongoid      || exit $?
bundle install                  || exit $?
rvm use ruby-1.9.2-head@mongoid || exit $?
bundle install                  || exit $?
rvm use ree@mongoid             || exit $?
bundle install                  || exit $?
rvm 1.8.7,1.9.1,1.9.2-head,ree specs
