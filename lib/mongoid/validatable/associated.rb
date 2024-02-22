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
          # grab the proxy from the instance variable directly; we don't want
          # any loading logic to run; we just want to see if it's already
          # been loaded.
          proxy = document.ivar(attribute)
          next true unless proxy

          # if the variable exists, now we see if it is a proxy, or an actual
          # document. It might be a literal document instead of a proxy if this
          # document was created with a Document instance as a provided attribute,
          # e.g. "Post.new(message: Message.new)".
          target = proxy.respond_to?(:_target) ? proxy._target : proxy
          next true if target.respond_to?(:_loaded?) && !target._loaded?

          # Now, treating the target as an array, look at each element
          # and see if it is valid, but only if it has already been
          # persisted, or changed, and hasn't been flagged for destroy.
          Array.wrap(target).all? do |value|
            if value && !value.flagged_for_destroy? && (!value.persisted? || value.changed?)
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
