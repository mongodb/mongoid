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
    #     references_many :posts, :validate => true
    #   end
    class ReferencedValidator < ActiveModel::EachValidator

      # Validate the document for the initialized attributes. Will not load
      # any association that's not currently loaded.
      #
      # @param [ Document ] document The document to validate.
      def validate(document)
        attributes.each do |attribute|
          value = document.instance_variable_get("@#{attribute}".to_sym)
          validate_each(document, attribute, value)
        end
      end

      # Validates that the already loaded associations provided are either all
      # nil or unchanged or all valid. If neither is true then the appropriate
      # errors will be added to the parent document.
      #
      # @example Validate the loaded association.
      #   validator.validate_each(document, :name, name)
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The relation to validate.
      # @param [ Object ] value The value of the relation.
      def validate_each(document, attribute, value)
        document.validated = true
        valid =
          if !value || !value.target
            true
          else
            Array.wrap(value).collect do |doc|
              if doc.nil? || (!doc.changed? && !doc.new_record?)
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
