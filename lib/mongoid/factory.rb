# encoding: utf-8
module Mongoid

  # Instantiates documents that came from the database.
  module Factory
    extend self

    # Builds a new +Document+ from the supplied attributes.
    #
    # @example Build the document.
    #   Mongoid::Factory.build(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    # @param [ Hash ] options The mass assignment scoping options.
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = nil, opts = {})
      type = (attributes || {})["_type"]
      if type && klass._types.include?(type)
        type.constantize.new(attributes, opts)
      else
        klass.new(attributes, opts)
      end
    end

    # Builds a new +Document+ from the supplied attributes loaded from the
    # database.
    #
    # @example Build the document.
    #   Mongoid::Factory.from_db(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    # @param [ Array ] selected_fields If instantiated from a criteria using
    #   #only we give the document a list of the selected fields.
    #
    # @return [ Document ] The instantiated document.
    def from_db(klass, attributes = nil, selected_fields = nil)
      type = (attributes || {})["_type"]
      if type.blank?
        klass.instantiate(attributes, selected_fields)
      else
        type.camelize.constantize.instantiate(attributes, selected_fields)
      end
    end
  end
end
