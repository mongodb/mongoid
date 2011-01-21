# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:

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
      def validate_each(document, attribute, value)
        unless document.validated?
          document.validated = true
          return if Array.wrap(value).collect { |doc| doc.nil? || doc.valid? }.all?
          document.errors.add(attribute, :invalid, options.merge(:value => value))
        else
          document.validated = false
        end
      end
    end
  end
end
