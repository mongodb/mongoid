# encoding: utf-8
module Mongoid #:nodoc:
  module Validations #:nodoc:

    # Validates whether or not an association is valid or not. Will correctly
    # handle has one and has many associations. Will *not* load associations if
    # they aren't already in memory.
    #
    # @example Set up the association validations.
    #
    #   class Person
    #     include Mongoid::Document
    #     embeds_one :name
    #     embeds_many :addresses
    #
    #     validates_relation :name, :addresses
    #   end
    class ReferencedValidator < ActiveModel::EachValidator

      # TODO docs
      def validate(document)
        attributes.each do |attribute|
          value = document.instance_variable_get("@#{attribute}".to_sym)
          validate_each(document, attribute, value)
        end
      end

      # TODO docs
      def validate_each(document, attribute, value)
        document.validated = true
        valid =
          if !value || !value.loaded
            true
          else
            Array.wrap(value).collect do |doc|
              if doc.nil?
                true
              else
                doc.validated? ? true : doc.valid?
              end
            end.all?
          end
        document.validated = false
        return if valid
        document.errors.add(attribute, :invalid, options.merge(:value => value))
      end
    end
  end
end
