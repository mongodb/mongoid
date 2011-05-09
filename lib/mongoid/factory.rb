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
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = {}, loading = true)
      attrs = {}.merge(attributes)
      type = attrs["_type"]
      if type.present?
        instantiate(attrs, type.constantize, loading)
      else
        instantiate(attrs, klass, loading)
      end
    end

    private

    # Instantiate the document. If we are loading from the database then use
    # instantiate, otherwise use new.
    #
    # @example Instantiate the document.
    #   factory.instantiate({}, Person, true)
    #
    # @return [ Document ] The document..
    #
    # @since 2.0.2
    def instantiate(attributes, klass, loading)
      loading ? klass.instantiate(attributes) : klass.new(attributes)
    end
  end
end
