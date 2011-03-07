# encoding: utf-8
module Mongoid #:nodoc:
  class Factory #:nodoc:
    # Builds a new +Document+ from the supplied attributes.
    #
    # Example:
    #
    # <tt>Mongoid::Factory.build(Person, {})</tt>
    #
    # Options:
    #
    # klass: The class to instantiate from if _type is not present.
    # attributes: The +Document+ attributes.
    def self.build(klass, attributes)
      attrs = {}.merge(attributes)
      type = attrs["_type"]
      type.present? ? type.constantize.instantiate(attrs) : klass.instantiate(attrs)
    end
  end
end
