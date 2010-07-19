#!/bin/bash
rvm use ruby-1.8.7@mongoid
bundle
rvm use ruby-1.9.1@mongoid
bundle
rvm use ruby-1.9.2-head@mongoid
bundle
