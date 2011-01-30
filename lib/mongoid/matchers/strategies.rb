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
require "mongoid/matchers/or"
require "mongoid/matchers/size"

module Mongoid #:nodoc:
  module Matchers #:nodoc:

    # This module is responsible for returning the correct matcher given a
    # MongoDB query expression.
    module Strategies
      extend self

      MATCHERS = {
        "$all" => Matchers::All,
        "$exists" => Matchers::Exists,
        "$gt" => Matchers::Gt,
        "$gte" => Matchers::Gte,
        "$in" => Matchers::In,
        "$lt" => Matchers::Lt,
        "$lte" => Matchers::Lte,
        "$ne" => Matchers::Ne,
        "$nin" => Matchers::Nin,
        "$or" => Matchers::Or,
        "$size" => Matchers::Size
      }

      # Get the matcher for the supplied key and value. Will determine the class
      # name from the key.
      #
      # @example Get the matcher.
      #   document.matcher(:title, { "$in" => [ "test" ] })
      #
      # @param [ Document ] document The document to check.
      # @param [ Symbol, String ] key The field name.
      # @param [ Object, Hash ] The value or selector.
      #
      # @return [ Matcher ] The matcher.
      #
      # @since 2.0.0.rc.7
      def matcher(document, key, value)
        if value.is_a?(Hash)
          MATCHERS[value.keys.first].new(document.attributes[key])
        else
          if key == "$or"
            Matchers::Or.new(value, document)
          else
            Default.new(document.attributes[key])
          end
        end
      end
    end
  end
end
