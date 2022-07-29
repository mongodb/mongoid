# frozen_string_literal: true

module Mongoid
  module Validatable
    module Macros
      extend ActiveSupport::Concern

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
      # @param [ Object... ] *args The arguments to pass to the validator.
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
      # @param [ Object... ] *args The arguments to pass to the validator.
      def validates_uniqueness_of(*args)
        validates_with(UniquenessValidator, _merge_attributes(args))
      end

      # Validates the format of a field.
      #
      # @example
      #   class Person
      #     include Mongoid::Document
      #     field :title
      #
      #     validates_format_of :title, with: /\A[a-z0-9 \-_]*\z/i
      #   end
      #
      # @param [ Object... ] *args The names of the field(s) to validate.
      def validates_format_of(*args)
        validates_with(FormatValidator, _merge_attributes(args))
      end

      # Validates the length of a field.
      #
      # @example
      #   class Person
      #     include Mongoid::Document
      #     field :title
      #
      #     validates_length_of :title, minimum: 100
      #   end
      #
      # @param [ Object... ] *args The names of the field(s) to validate.
      def validates_length_of(*args)
        validates_with(LengthValidator, _merge_attributes(args))
      end

      # Validates whether or not a field is present - meaning nil or empty.
      #
      # @example
      #   class Person
      #     include Mongoid::Document
      #     field :title
      #
      #     validates_presence_of :title
      #   end
      #
      # @param [ Object... ] *args The names of the field(s) to validate.
      def validates_presence_of(*args)
        validates_with(PresenceValidator, _merge_attributes(args))
      end
    end
  end
end
