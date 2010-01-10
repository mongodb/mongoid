# encoding: utf-8
module Mongoid #:nodoc:
  module NamedScopes
    def scopes
      read_inheritable_attribute(:scopes) || write_inheritable_attribute(:scopes, {})
    end

    def named_scope(name, options = {}, &block)
      name = name.to_sym
      scopes[name] = lambda do |parent_scope, *args|
        CriteriaProxy.new(parent_scope, Hash === options ? options : options.call(*args), &block)
      end
      (class << self; self; end).class_eval <<-EOT
        def #{name}(*args)
          scopes[:#{name}].call(self, *args)
        end
      EOT
    end

    class CriteriaProxy
      attr_accessor :conditions, :klass, :parent_scope

      delegate :scopes, :to => :parent_scope

      def initialize(parent_scope, conditions, &block)
        conditions ||= {}
        [conditions.delete(:extend)].flatten.each { |extension| extend extension } if conditions.include?(:extend)
        extend Module.new(&block) if block_given?
        self.klass = parent_scope unless CriteriaProxy === parent_scope
        self.parent_scope, self.conditions = parent_scope, conditions
      end

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
        @found.criteria(conditions)
        @found
      end
    end
  end
end

