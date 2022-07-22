# frozen_string_literal: true

module Mongoid
  module Validatable

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
      def validate_each(document, attribute, value)
        field = document.fields[document.database_field_name(attribute)]
        if field.try(:localized?) && !value.blank?
          value.each_pair do |_locale, _value|
            document.errors.add(
              attribute,
              :blank_in_locale,
              **options.merge(location: _locale)
            ) if not_present?(_value)
          end
        elsif document.relations.has_key?(attribute.to_s)
          if relation_or_fk_missing?(document, attribute, value)
            document.errors.add(attribute, :blank, **options)
          end
        else
          document.errors.add(attribute, :blank, **options) if not_present?(value)
        end
      end

      private

      # Returns true if the association is blank or the foreign key is blank.
      #
      # @api private
      #
      # @example Check is the association or fk is blank.
      #   validator.relation_or_fk_missing(doc, :name, "")
      #
      # @param [ Document ] doc The document.
      # @param [ Symbol ] attr The attribute.
      # @param [ Object ] value The value.
      #
      # @return [ true | false ] If the doc is missing.
      def relation_or_fk_missing?(doc, attr, value)
        return true if value.blank? && doc.send(attr).blank?
        association = doc.relations[attr.to_s]
        association.stores_foreign_key? && doc.send(association.foreign_key).blank?
      end

      # For guarding against false values.
      #
      # @api private
      #
      # @example Is the value not present?
      #   validator.not_present?(value)
      #
      # @param [ Object ] value The value.
      #
      # @return [ true | false ] If the value is not present.
      def not_present?(value)
        value.blank? && value != false
      end
    end
  end
end
