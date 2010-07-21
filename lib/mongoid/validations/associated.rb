# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:
    # Validates whether or not an association is valid or not. Will correctly
    # handle has one and has many associations.
    #
    # Example:
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
      # Example:
      #
      # <tt>validator.validate_each(document, :name, name)</tt>
      def validate_each(document, attribute, value)
        values = value.is_a?(Array) ? value : [ value ]
        return if values.collect { |doc| doc.nil? || doc.valid? }.all?
        document.errors.add(attribute, :invalid, options.merge!(:value => value))
      end
    end
  end
end
