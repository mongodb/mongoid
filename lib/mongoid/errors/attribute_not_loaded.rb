# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # Raised when attempting to read or write an attribute which has
    # not been loaded. This can occur when using `.only` or `.without`
    # query projection methods.
    #
    # @example Getting a field which has not been loaded.
    #   Band.only(:name).first.label
    #   #=> raises Mongoid::Errors::AttributeNotLoaded
    #
    # @example Setting a field which has not been loaded.
    #   Band.without(:label).first.label = 'Sub Pop Records'
    #   #=> raises Mongoid::Errors::AttributeNotLoaded
    class AttributeNotLoaded < MongoidError

      # Create the new error.
      #
      # @example Instantiate the error.
      #   AttributeNotLoaded.new(Person, "title")
      #
      # @param [ Class ] klass The model class.
      # @param [ String | Symbol ] name The name of the attribute.
      def initialize(klass, name)
        super(
          compose_message("attribute_not_loaded", { klass: klass.name, name: name })
        )
      end
    end
  end
end
