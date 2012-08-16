# encoding: utf-8
module Mongoid
  module Validations

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
          value.each_pair do |_locale, _value|
            document.errors.add(
              attribute,
              :blank_in_locale,
              options.merge(location: _locale)
            ) if not_present?(_value)
          end
        elsif document.relations.has_key?(attribute.to_s)
          if relation_or_fk_missing?(document, attribute, value)
            document.errors.add(attribute, :blank, options)
          end
        else
          document.errors.add(attribute, :blank, options) if not_present?(value)
        end
      end

      private

      # Returns true if the relation is blank or the foreign key is blank.
      #
      # @api private
      #
      # @example Check is the relation or fk is blank.
      #   validator.relation_or_fk_mising(doc, :name, "")
      #
      # @param [ Document ] doc The document.
      # @param [ Symbol ] attr The attribute.
      # @param [ Object ] value The value.
      #
      # @return [ true, false ] If the doc is missing.
      #
      # @since 3.0.0
      def relation_or_fk_missing?(doc, attr, value)
        return true if value.blank? && doc.send(attr).blank?
        metadata = doc.relations[attr.to_s]
        metadata.stores_foreign_key? && doc.send(metadata.foreign_key).blank?
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
      # @return [ true, false ] If the value is not present.
      #
      # @since 3.0.5
      def not_present?(value)
        value.blank? && value != false
      end
    end
  end
end
