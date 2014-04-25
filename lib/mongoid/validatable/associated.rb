# encoding: utf-8
module Mongoid
  module Validatable

    # Validates whether or not an association is valid or not. Will correctly
    # handle has one and has many associations.
    #
    # @example Set up the association validations.
    #
    #   class Person
    #     include Mongoid::Document
    #     embeds_one :name
    #     embeds_many :addresses
    #
    #     validates_associated :name, :addresses
    #   end
    class AssociatedValidator < ActiveModel::EachValidator

      # Validates that the associations provided are either all nil or all
      # valid. If neither is true then the appropriate errors will be added to
      # the parent document.
      #
      # @example Validate the association.
      #   validator.validate_each(document, :name, name)
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The relation to validate.
      # @param [ Object ] value The value of the relation.
      #
      # @since 2.0.0
      def validate_each(document, attribute, value)
        begin
          document.begin_validate
          valid = Array.wrap(value).collect do |doc|
            if doc.nil? || doc.flagged_for_destroy?
              true
            else
              doc.validated? ? true : doc.valid?
            end
          end.all?
        ensure
          document.exit_validate
        end
        document.errors.add(attribute, :invalid, options) unless valid
      end
    end
  end
end
