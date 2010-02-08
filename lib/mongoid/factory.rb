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
    # attributes: The +Document+ attributes.
    def self.build(attributes)
      attributes["_type"].constantize.instantiate(attributes)
    end
  end
end
