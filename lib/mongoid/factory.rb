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
    def self.build(klass, attrs)
      type = attrs["_type"]
      type ? type.constantize.fastload(attrs) : klass.fastload(attrs)
    end
  end
end
