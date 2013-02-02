module Mongoid
  module Validations
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

      # Validates the format of a field.
      #
      # @example
      #   class Person
      #     include Mongoid::Document
      #     field :title
      #
      #     validates_format_of :title, with: /^[a-z0-9 \-_]*$/i
      #   end
      #
      # @param [ Array ] args The names of the fields to validate.
      #
      # @since 2.4.0
      def validates_format_of(*args)
        validates_with(Mongoid::Validations::FormatValidator, _merge_attributes(args))
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
      # @param [ Array ] args The names of the fields to validate.
      #
      # @since 2.4.0
      def validates_length_of(*args)
        validates_with(Mongoid::Validations::LengthValidator, _merge_attributes(args))
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
      # @param [ Array ] args The names of the fields to validate.
      #
      # @since 2.4.0
      def validates_presence_of(*args)
        validates_with(PresenceValidator, _merge_attributes(args))
      end
    end
  end
end
