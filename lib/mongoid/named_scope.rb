# encoding: utf-8
module Mongoid #:nodoc:
  module NamedScope
    # Creates a named_scope for the +Document+, similar to ActiveRecord's
    # named_scopes. +NamedScopes+ are proxied +Criteria+ objects that can be
    # chained.
    #
    # Example:
    #
    #   class Person
    #     include Mongoid::Document
    #     field :active, :type => Boolean
    #     field :count, :type => Integer
    #
    #     named_scope :active, :where => { :active => true }
    #     named_scope :count_gt_one, :where => { :count.gt => 1 }
    #     named_scope :at_least_count, lambda { |count| { :where => { :count.gt => count } } }
    #   end
    def named_scope(name, options = {}, &block)
      name = name.to_sym
      scopes[name] = lambda do |parent, *args|
        Scope.new(parent, options.scoped(*args), &block)
      end
      (class << self; self; end).class_eval <<-EOT
        def #{name}(*args)
          scopes[:#{name}].call(self, *args)
        end
      EOT
    end

    # Return the scopes or default to an empty +Hash+.
    def scopes
      read_inheritable_attribute(:scopes) || write_inheritable_attribute(:scopes, {})
    end

  end
end

