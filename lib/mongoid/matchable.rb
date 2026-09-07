# frozen_string_literal: true
# rubocop:todo all

module Mongoid

  # This module contains all the behavior for Ruby implementations of MongoDB
  # selectors.
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
    # @return [ true | false ] True if matches, false if not.
    def _matches?(selector)
      # Opens a regexp budget for this document only. Callers that match many
      # documents against one selector open a budget of their own first, and
      # this one joins it rather than giving every document a fresh limit.
      Matcher::RegexpBudget.open(selector) do
        Matcher::Expression.matches?(self, selector)
      end
    end
  end
end
