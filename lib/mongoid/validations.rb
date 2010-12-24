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
    end
  end
end
