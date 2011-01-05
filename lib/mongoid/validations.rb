# encoding: utf-8
require "mongoid/validations/associated"
require "mongoid/validations/uniqueness"

module Mongoid #:nodoc:

  # This module provides additional validations that ActiveModel does not
  # provide: validates_associated and validates_uniqueness_of.
  module Validations
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Validations

      # Overrides the default ActiveModel behaviour since we need to handle
      # validations of relations slightly different than just calling the
      # getter.
      #
      # @todo Durran: Why does moving the ActiveModel::Validations include
      #   statement outside of the block bomb the test suite. This feels dirty.
      #
      # @example Read the value.
      #   person.read_attribute_for_validation(:addresses)
      #
      # @param [ Symbol ] attr The name of the field or relation.
      #
      # @return [ Object ] The value of the field or the relation.
      def read_attribute_for_validation(attr)
        relations[attr.to_s] ? send(attr, false, :continue => false) : send(attr)
      end
    end

    module ClassMethods #:nodoc:

      # Validates whether or not an association is valid or not. Will correctly
      # handle has one and has many associations.
      #
      # @example
      #
      #   class Person
      #     include Mongoid::Document
      #     embeds_one :name
      #     embeds_many :addresses
      #
      #     validates_associated :name, :addresses
      #   end
      #
      # @param [ Array ] *args The arguments to pass to the validator.
      def validates_associated(*args)
        validates_with(AssociatedValidator, _merge_attributes(args))
      end

      # Validates whether or not a field is unique against the documents in the
      # database.
      #
      # @example
      #
      #   class Person
      #     include Mongoid::Document
      #     field :title
      #
      #     validates_uniqueness_of :title
      #   end
      #
      # @param [ Array ] *args The arguments to pass to the validator.
      def validates_uniqueness_of(*args)
        validates_with(UniquenessValidator, _merge_attributes(args))
      end

      protected

      # Adds an associated validator for the relation if the validate option
      # was not provided or set to true.
      #
      # @example Set up validation.
      #   Person.validate_relation(metadata)
      #
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @since 2.0.0.rc.1
      def validate_relation(metadata)
        validates_associated(metadata.name) if metadata.validate?
      end
    end
  end
end
