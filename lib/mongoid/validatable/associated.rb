# frozen_string_literal: true
# rubocop:todo all

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
    class AssociatedValidator < ActiveModel::Validator
      attr_reader :attributes

      def initialize(options)
        @attributes = options[:attributes]
      end

      # Checks that the named associations of the given record
      # (`attributes`) are valid. This does NOT load the associations
      # from memory, and will only validate records that are dirty
      # or unpersisted.
      #
      # If anything is not valid, appropriate errors will be added to
      # the `document` parameter.
      #
      # @param [ Mongoid::Document ] document the document with the
      #   associations to validate.
      def validate(document)
        attributes.each do |attr_name|
          validate_association(document, attr_name)
        end
      end

      private

      # Validates that the given association provided is either nil,
      # persisted and unchanged, or invalid. Otherwise, the appropriate errors
      # will be added to the parent document.
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The association to validate.
      def validate_association(document, attribute)
        valid = document.validating do
          Array(document.ivar(attribute)).all? do |value|
            if value && (!value.persisted? || value.changed?)
              value.validated? ? true : value.valid?
            else
              true
            end
          end
        end

        document.errors.add(attribute, :invalid) unless valid
      end
    end
  end
end
