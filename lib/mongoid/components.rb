# encoding: utf-8
module Mongoid #:nodoc:
  module Components
    def self.included(base)
      base.class_eval do
        include Associations
        include Attributes
        include Callbacks
        include Commands
        include Memoization
        include Observable
        include Validatable
        extend Finders
      end
    end
  end
end
