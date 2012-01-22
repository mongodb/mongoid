# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:

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
      def validate_each(document, attribute, value)
        field = document.fields[attribute.to_s]
        if field && field.localized? && !value.blank?
          value.each_pair do |_locale, _value|
            super(document, attribute, _value)
          end
        else
          super
        end
      end
    end
  end
end
