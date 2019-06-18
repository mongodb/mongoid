# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Validatable

    # Validates that the specified attributes do or do not match a certain
    # regular expression.
    #
    # @example Set up the format validator.
    #
    #   class Person
    #     include Mongoid::Document
    #     field :website
    #
    #     validates_format_of :website, :with => URI.regexp
    #   end
    class FormatValidator < ActiveModel::Validations::FormatValidator
      include Localizable
    end
  end
end
