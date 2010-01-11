# encoding: utf-8
module Mongoid #:nodoc
  module Components #:nodoc
    def self.included(base)
      base.class_eval do
        # All modules that a +Document+ is composed of are defined in this
        # module, to keep the document class from getting too cluttered.
        include Associations
        include Attributes
        include Callbacks
        include Commands
        include Fields
        include Indexes
        include Memoization
        include Observable
        include Validatable
        extend Finders
        extend NamedScope
      end
    end
  end
end
