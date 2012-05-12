# encoding: utf-8
module Mongoid #:nodoc:

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
    # @param [ Hash ] optiosn The mass assignment scoping options.
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = nil, options = {})
      type = (attributes || {})["_type"]
      if type && klass._types.include?(type)
        type.constantize.new(attributes, options)
      else
        klass.new(attributes, options)
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
    #
    # @return [ Document ] The instantiated document.
    def from_db(klass, attributes = nil)
      type = (attributes || {})["_type"]
      if type.blank?
        klass.instantiate(attributes)
      else
        type.camelize.constantize.instantiate(attributes)
      end
    end
  end
end
