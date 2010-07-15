#!/bin/bash
rvm use ruby-1.8.7
bundle exec rake spec
rvm use ruby-1.9.1
bundle exec rake spec
rvm use ruby-1.9.2-head
bundle exec rake spec
