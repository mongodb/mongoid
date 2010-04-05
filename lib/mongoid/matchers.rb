# encoding: utf-8
require "mongoid/matchers/default"
require "mongoid/matchers/all"
require "mongoid/matchers/exists"
require "mongoid/matchers/gt"
require "mongoid/matchers/gte"
require "mongoid/matchers/in"
require "mongoid/matchers/lt"
require "mongoid/matchers/lte"
require "mongoid/matchers/ne"
require "mongoid/matchers/nin"
require "mongoid/matchers/size"

module Mongoid #:nodoc:
  module Matchers
    # Determines if this document has the attributes to match the supplied
    # MongoDB selector. Used for matching on embedded associations.
    def matches?(selector)
      selector.each_pair do |key, value|
        return false unless matcher(key, value).matches?(value)
      end; true
    end

    protected
    # Get the matcher for the supplied key and value. Will determine the class
    # name from the key.
    def matcher(key, value)
      if value.is_a?(Hash)
        name = "Mongoid::Matchers::#{value.keys.first.gsub("$", "").camelize}"
        return name.constantize.new(attributes[key])
      end
      Default.new(attributes[key])
    end
  end
end
