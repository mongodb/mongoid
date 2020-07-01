# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # This module contains all the behavior for Ruby implementations of MongoDB
  # selectors.
  #
  # @since 4.0.0
  module Matchable
    extend ActiveSupport::Concern

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
      Matcher::Expression.matches?(self, selector)
    end
  end
end
