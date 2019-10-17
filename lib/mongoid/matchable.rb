# frozen_string_literal: true
# encoding: utf-8

require "mongoid/matchable/default"
require "mongoid/matchable/all"
require "mongoid/matchable/and"
require "mongoid/matchable/elem_match"
require "mongoid/matchable/eq"
require "mongoid/matchable/exists"
require "mongoid/matchable/gt"
require "mongoid/matchable/gte"
require "mongoid/matchable/in"
require "mongoid/matchable/lt"
require "mongoid/matchable/lte"
require "mongoid/matchable/ne"
require "mongoid/matchable/nin"
require "mongoid/matchable/nor"
require "mongoid/matchable/or"
require "mongoid/matchable/regexp"
require "mongoid/matchable/size"

module Mongoid

  # This module contains all the behavior for Ruby implementations of MongoDB
  # selectors.
  #
  # @since 4.0.0
  module Matchable
    extend ActiveSupport::Concern

    # Hash lookup for the matcher for a specific operation.
    #
    # @since 1.0.0
    MATCHERS = {
      "$all" => All,
      "$and" => And,
      "$elemMatch" => ElemMatch,
      "$eq" => Eq,
      "$exists" => Exists,
      "$gt" => Gt,
      "$gte" => Gte,
      "$in" => In,
      "$lt" => Lt,
      "$lte" => Lte,
      "$ne" => Ne,
      "$nin" => Nin,
      "$nor" => Nor,
      "$or" => Or,
      "$size" => Size,
    }.with_indifferent_access.freeze

    # Determines if this document has the attributes to match the supplied
    # MongoDB selector. Used for matching on embedded associations.
    #
    # @example Does the document match?
    #   document._matches?(:title => { "$in" => [ "test" ] })
    #
    # @param [ Hash ] selector The MongoDB selector.
    #
    # @return [ true, false ] True if matches, false if not.
    #
    # @since 1.0.0
    def _matches?(selector)
      selector.each_pair do |key, value|
        if value.is_a?(Hash)
          value.each do |item|
            if item[0].to_s == "$not".freeze
              item = item[1]
              return false if matcher(key, item)._matches?(item)
            else
              return false unless matcher(key, Hash[*item])._matches?(Hash[*item])
            end
          end
        else
          return false unless matcher(key, value)._matches?(value)
        end
      end
      true
    end

    private

    # Get the matcher for the supplied key and value. Will determine the class
    # name from the key.
    #
    # @example Get the matcher.
    #   document.matcher(:title, { "$in" => [ "test" ] })
    #
    # @param [ Symbol, String ] key The field name.
    # @param [ Object, Hash ] value The value or selector.
    #
    # @return [ Matcher ] The matcher.
    #
    # @since 2.0.0.rc.7
    # @api private
    def matcher(key, value)
      Matchable.matcher(self, key, value)
    end

    class << self

      # Get the matcher for the supplied key and value. Will determine the class
      # name from the key.
      #
      # @api private
      #
      # @example Get the matcher.
      #   Matchable.matcher(document, :title, { "$in" => [ "test" ] })
      #
      # @param [ Document ] document The document to check.
      # @param [ Symbol, String ] key The field name.
      # @param [ Object, Hash ] value The value or selector.
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
        elsif value.regexp?
          Regexp.new(extract_attribute(document, key))
        else
          case key.to_s
            when "$or" then Or.new(value, document)
            when "$and" then And.new(value, document)
            when "$nor" then Nor.new(value, document)
            else Default.new(extract_attribute(document, key))
          end
        end
      end

      private

      # Extract the attribute from the key, being smarter about dot notation.
      #
      # @api private
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
      # @api private
      def extract_attribute(document, key)
        if (key_string = key.to_s) =~ /.+\..+/
          key_string.split('.').inject(document.send(:as_attributes)) do |_attribs, _key|
            if _attribs.is_a?(::Array)
              if _key =~ /\A\d+\z/ && _attribs.none? {|doc| doc.is_a?(Hash)}
                _attribs.try(:[], _key.to_i)
              else
                _attribs.map { |doc| doc.try(:[], _key) }
              end
            else
              _attribs.try(:[], _key)
            end
          end
        else
          if document.is_a?(Hash)
            document[key_string]
          else
            document.attributes[key_string]
          end
        end
      end
    end
  end
end
