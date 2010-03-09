# encoding: utf-8
module Mongoid #:nodoc
  module Components #:nodoc
    def self.included(base)
      base.class_eval do
        # All modules that a +Document+ is composed of are defined in this
        # module, to keep the document class from getting too cluttered.
        include Mongoid::Associations
        include Mongoid::Attributes
        include Mongoid::Caching
        include Mongoid::Callbacks
        include Mongoid::Commands
        include Mongoid::Extras
        include Mongoid::Fields
        include Mongoid::Indexes
        include Mongoid::Matchers
        include Mongoid::Memoization
        include Observable
        include Validatable
        extend Mongoid::Finders
        extend Mongoid::NamedScope
      end
    end
  end
end
