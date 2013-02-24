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
    def build(klass, attributes = nil)
      type = (attributes || {})["_type"]
      if type && klass._types.include?(type)
        type.constantize.new(attributes)
      else
        klass.new(attributes)
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
    def from_db(klass, attributes = nil, criteria_instance_id = nil)
      type = (attributes || {})["_type"]
      
      klass = type.blank? ? klass : type.camelize.constantize
      
      klass.instantiate(attributes, criteria_instance_id)
    end
    
    # Retrieves a +Document+ from the Identity map or builds a new +Document+
    # from the supplied attributes loaded from the database.
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    #
    # @return [ Document ] The found or instantiated document.
    def from_map_or_db(klass, attributes = nil, criteria_instance_id = nil)
      type = (attributes || {})["_type"]
      id = (attributes || {})["_id"]
      
      klass = type.blank? ? klass : type.camelize.constantize
      result = IdentityMap.get(klass, id)
      result ||= klass.instantiate(attributes, criteria_instance_id)
    end
  end
end
