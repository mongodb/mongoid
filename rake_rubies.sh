#!/bin/bash
rvm use ruby-1.8.7@mongoid
bundle exec rake spec
rvm use ruby-1.9.1@mongoid
bundle exec rake spec
rvm use ruby-1.9.2-head@mongoid
bundle exec rake spec
