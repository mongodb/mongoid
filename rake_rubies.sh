#!/bin/bash
rvm ruby-1.8.7@mongoid ruby -S bundle install      || exit $?
rvm ruby-1.9.1@mongoid ruby -S bundle install      || exit $?
rvm ruby-1.9.2@mongoid ruby -S bundle install || exit $?
rvm ree@mongoid ruby -S bundle install             || exit $?
rvm 1.8.7@mongoid,1.9.1,1.9.2,ree rake spec:progress
