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
      # Required by `validates_with` so that the validator
      # gets added to the correct attributes.
      def attributes
        options[:attributes]
      end

      # Checks that the named associations of the given record
      # (`attributes`) are valid. This does NOT load the associations
      # from the database, and will only validate records that are dirty
      # or unpersisted.
      #
      # If anything is not valid, appropriate errors will be added to
      # the `document` parameter.
      #
      # @param [ Mongoid::Document ] document the document with the
      #   associations to validate.
      def validate(document)
        options[:attributes].each do |attr_name|
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
        # grab the proxy from the instance variable directly; we don't want
        # any loading logic to run; we just want to see if it's already
        # been loaded.
        proxy = document.ivar(attribute)
        return unless proxy

        # if the variable exists, now we see if it is a proxy, or an actual
        # document. It might be a literal document instead of a proxy if this
        # document was created with a Document instance as a provided attribute,
        # e.g. "Post.new(message: Message.new)".
        target = proxy.respond_to?(:_target) ? proxy._target : proxy

        # Now, fetch the list of documents from the target. Target may be a
        # single value, or a list of values, and in the case of HasMany,
        # might be a rather complex collection. We need to do this without
        # triggering a load, so it's a bit of a delicate dance.
        list = get_target_documents(target)

        valid = document.validating do
          # Now, treating the target as an array, look at each element
          # and see if it is valid, but only if it has already been
          # persisted, or changed, and hasn't been flagged for destroy.
          list.all? do |value|
            if value && !value.flagged_for_destroy? && (!value.persisted? || value.changed?)
              value.validated? ? true : value.valid?
            else
              true
            end
          end
        end

        document.errors.add(attribute, :invalid) unless valid
      end

      private

      # Examine the given target object and return an array of
      # documents (possibly empty) that the target represents.
      #
      # @param [ Array | Mongoid::Document | Mongoid::Association::Proxy | HasMany::Enumerable ] target
      #   the target object to examine.
      #
      # @return [ Array<Mongoid::Document> ] the list of documents
      def get_target_documents(target)
        if target.respond_to?(:_loaded?)
          get_target_documents_for_has_many(target)
        else
          get_target_documents_for_other(target)
        end
      end

      # Returns the list of all currently in-memory values held by
      # the target. The target will not be loaded.
      #
      # @param [ HasMany::Enumerable ] target the target that will
      #   be examined for in-memory documents.
      #
      # @return [ Array<Mongoid::Document> ] the in-memory documents
      #   held by the target.
      def get_target_documents_for_has_many(target)
        [ *target._loaded.values, *target._added.values ]
      end

      # Returns the target as an array. If the target represents a single
      # value, it is wrapped in an array.
      #
      # @param [ Array | Mongoid::Document | Mongoid::Association::Proxy ] target
      #   the target to return.
      #
      # @return [ Array<Mongoid::Document> ] the target, as an array.
      def get_target_documents_for_other(target)
        Array.wrap(target)
      end
    end
  end
end
