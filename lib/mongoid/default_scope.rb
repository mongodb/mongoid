# encoding: utf-8
module Mongoid #:nodoc:
  module DefaultScope
    # Creates a default_scope for the +Document+, similar to ActiveRecord's
    # default_scope. +DefaultScopes+ are proxied +Criteria+ objects that are
    # applied by default to all queries for the class.

    # Example:
    #
    #   class Person
    #     include Mongoid::Document
    #     field :active, :type => Boolean
    #     field :count, :type => Integer
    #
    #     default_scope :where => { :active => true }
    #   end
    def default_scope(conditions = {}, &block)
      self.scope_stack << criteria.fuse(Scope.new(conditions, &block).conditions.scoped)
    end
  end
end
