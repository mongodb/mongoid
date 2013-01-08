# encoding: utf-8
require "mongoid/matchers/default"
require "mongoid/matchers/all"
require "mongoid/matchers/and"
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

module Mongoid
  module Matchers

    # This module is responsible for returning the correct matcher given a
    # MongoDB query expression.
    module Strategies
      extend self

      MATCHERS = {
        "$all" => Matchers::All,
        "$and" => Matchers::And,
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
      }.with_indifferent_access

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
          matcher = MATCHERS[value.keys.first]
          if matcher
            matcher.new(extract_attribute(document, key))
          else
            Default.new(extract_attribute(document, key))
          end
        else
          case key.to_s
            when "$or" then Matchers::Or.new(value, document)
            when "$and" then Matchers::And.new(value, document)
            else Default.new(extract_attribute(document, key))
          end
        end
      end

      private

      # Extract the attribute from the key, being smarter about dot notation.
      #
      # @example Extract the attribute.
      #   strategy.extract_attribute(doc, "info.field")
      #
      # @param [ Document ] document The document.
      # @param [ String ] key The key.
      #
      # @return [ Object ] The value of the attribute.
      #
      # @since 2.2.1
      def extract_attribute(document, key)
        if (key_string = key.to_s) =~ /.+\..+/
          key_string.split('.').inject(document.as_document) do |_attribs, _key|
            if _attribs.is_a?(::Array)
              _attribs.map { |doc| doc.try(:[], _key) }
            else
              _attribs.try(:[], _key)
            end
          end
        else
          document.attributes[key_string]
        end
      end
    end
  end
end
