# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:

    # Validates that the specified attributes are not blank (as defined by
    # Object#blank?).
    #
    # @example Define the presence validator.
    #
    #   class Person
    #     include Mongoid::Document
    #     field :title
    #
    #     validates_presence_of :title
    #   end
    class PresenceValidator < ActiveModel::EachValidator

      # Validate the document for the attribute and value.
      #
      # @example Validate the document.
      #   validator.validate_each(doc, :title, "")
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The attribute name.
      # @param [ Object ] value The current value of the field.
      #
      # @since 2.4.0
      def validate_each(document, attribute, value)
        field = document.fields[attribute.to_s]
        if field.try(:localized?) && !value.blank?
          value.each_pair do |locale, value|
            document.errors.add(attribute, :blank_on_locale, options.merge(:location => locale)) if value.blank?
          end
        elsif document.relations.has_key?(attribute.to_s)
          if value.blank? && document.send(attribute).blank?
            document.errors.add(attribute, :blank, options)
          end
        else
          document.errors.add(attribute, :blank, options) if value.blank?
        end
      end
    end
  end
end
