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

      # Validates each for format.
      #
      # @example Validate format.
      #   validator.validate_each(model, :name, "value")
      #
      # @param [ Document ] document The document.
      # @param [ Symbol, String ] attribute The attribute to validate.
      # @param [ Object ] value The attribute value.
      #
      # @since 2.4.2
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
