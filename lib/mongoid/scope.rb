# encoding: utf-8
module Mongoid #:nodoc:
  class Scope #:nodoc:

    delegate :scopes, :to => "@parent"

    # Create the new +Scope+. If a block is passed in, this Scope will extend
    # the block.
    #
    # Options:
    #
    # parent: The class the scope belongs to, or a parent +Scope+.
    # conditions: A +Hash+ of conditions.
    #
    # Example:
    #
    #   Mongoid::Scope.new(Person, { :title => "Sir" }) do
    #     def knighted?
    #       title == "Sir"
    #     end
    #   end
    def initialize(parent, conditions, &block)
      @parent, @conditions = parent, conditions
      extend Module.new(&block) if block_given?
    end

    # Return the class for the +Scope+. This will be the parent if the parent
    # is a class, otherwise will be nil.
    def klass
      @klass ||= @parent unless @parent.is_a?(Scope)
    end

    # Chaining is supported through method_missing. If a scope is already
    # defined with the method name the call will be passed there, otherwise it
    # will be passed to the target or parent.
    def method_missing(name, *args, &block)
      if scopes.include?(name)
        scopes[name].call(self, *args)
      elsif klass
        target.send(name, *args, &block)
      else
        @parent.fuse(@conditions); @parent.send(name, *args, &block)
      end
    end

    # The +Scope+ must respond like a +Criteria+ object. If this is a parent
    # criteria delegate to the target, otherwise bubble up to the parent.
    def respond_to?(name)
      super || (klass ? target.respond_to?(name) : @parent.respond_to?(name))
    end

    # Returns the target criteria if it has already been set or creates a new
    # criteria from the parent class.
    def target
      @target ||= klass.criteria.fuse(@conditions)
    end
  end
end

