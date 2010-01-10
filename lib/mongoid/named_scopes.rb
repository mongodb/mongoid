# encoding: utf-8
module Mongoid #:nodoc:
  module NamedScopes
    # Return the scopes or default to an empty +Hash+.
    def scopes
      read_inheritable_attribute(:scopes) || write_inheritable_attribute(:scopes, {})
    end

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
      scopes[name] = lambda do |parent_scope, *args|
        CriteriaProxy.new(parent_scope, options.is_a?(Hash) ? options : options.call(*args), &block)
      end
      (class << self; self; end).class_eval <<-EOT
        def #{name}(*args)
          scopes[:#{name}].call(self, *args)
        end
      EOT
    end

    class CriteriaProxy #:nodoc
      attr_accessor :conditions, :klass, :parent_scope

      delegate :scopes, :to => :parent_scope

      # Instantiate the new +CriteriaProxy+. If the conditions contains an
      # extension, the proxy will extend from that module. If a block is given
      # it will be extended as well.
      #
      # Example:
      #
      # <tt>CriteriaProxy.new(parent, :where => { :active => true })</tt>
      def initialize(parent_scope, conditions = {}, &block)
        [ conditions.delete(:extend) ].flatten.each { | ext| extend ext } if conditions.include?(:extend)
        extend Module.new(&block) if block_given?
        self.klass = parent_scope unless parent_scope.is_a?(CriteriaProxy)
        self.parent_scope, self.conditions = parent_scope, conditions
      end

      # First check if the proxy has the scope defined, otherwise look to the
      # parent scope.
      def respond_to?(method, include_private = false)
        super || if klass
          proxy_found.respond_to?(method, include_private)
        else
          parent_scope.respond_to?(method, include_private)
        end
      end

      protected

      def proxy_found
        @found || load_found
      end

      private

      def method_missing(method, *args, &block)
        if scopes.include?(method)
          scopes[method].call(self, *args)
        elsif klass
          proxy_found.send(method, *args, &block)
        else
          parent_scope.criteria(conditions)
          parent_scope.send(method, *args, &block)
        end
      end

      def load_found
        @found = Criteria.new(klass)
        @found.criteria(conditions); @found
      end
    end
  end
end

