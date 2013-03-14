# encoding: utf-8
module Mongoid

  # This module contains behaviour for all Mongoid scoping - named scopes,
  # default scopes, and criteria accessors via scoped and unscoped.
  module Scoping
    extend ActiveSupport::Concern

    included do
      class_attribute :default_scoping
      class_attribute :scopes
      self.scopes = {}
    end

    module ClassMethods

      # Add a default scope to the model. This scope will be applied to all
      # criteria unless #unscoped is specified.
      #
      # @example Define a default scope with a criteria.
      #   class Band
      #     include Mongoid::Document
      #     field :active, type: Boolean
      #     default_scope where(active: true)
      #   end
      #
      # @example Define a default scope with a proc.
      #   class Band
      #     include Mongoid::Document
      #     field :active, type: Boolean
      #     default_scope ->{ where(active: true) }
      #   end
      #
      # @param [ Proc, Criteria ] scope The default scope.
      #
      # @raise [ Errors::InvalidScope ] If the scope is not a proc or criteria.
      #
      # @return [ Proc ] The default scope.
      #
      # @since 1.0.0
      def default_scope(value)
        check_scope_validity(value)
        self.default_scoping = process_default_scope(value)
      end

      # Is the class able to have the default scope applied?
      #
      # @example Can the default scope be applied?
      #   Band.default_scopable?
      #
      # @return [ true, false ] If the default scope can be applied.
      #
      # @since 3.0.0
      def default_scopable?
        default_scoping? && !Threaded.executing?(:without_default_scope)
      end

      # Get a queryable, either the last one on the scope stack or a fresh one.
      #
      # @api private
      #
      # @example Get a queryable.
      #   Model.queryable
      #
      # @return [ Criteria ] The queryable.
      #
      # @since 3.0.0
      def queryable
        scope_stack.last || Criteria.new(self)
      end

      # Create a scope that can be accessed from the class level or chained to
      # criteria by the provided name.
      #
      # @example Create named scopes.
      #
      #   class Person
      #     include Mongoid::Document
      #     field :active, type: Boolean
      #     field :count, type: Integer
      #
      #     scope :active, where(active: true)
      #     scope :at_least, ->(count){ where(:count.gt => count) }
      #   end
      #
      # @param [ Symbol ] name The name of the scope.
      # @param [ Proc, Criteria ] conditions The conditions of the scope.
      #
      # @raise [ Errors::InvalidScope ] If the scope is not a proc or criteria.
      # @raise [ Errors::ScopeOverwrite ] If the scope name already exists.
      #
      # @since 1.0.0
      def scope(name, value, &block)
        normalized = name.to_sym
        check_scope_validity(value)
        check_scope_name(normalized)
        scopes[normalized] = {
          scope: strip_default_scope(value),
          extension: Module.new(&block)
        }
        define_scope_method(normalized)
      end

      # Initializes and returns the current scope stack.
      #
      # @example Get the scope stack.
      #   Person.scope_stack
      #
      # @return [ Array<Criteria> ] The scope stack.
      #
      # @since 1.0.0
      def scope_stack
        Threaded.scope_stack[object_id] ||= []
      end

      # Get a criteria for the document with normal scoping.
      #
      # @example Get the criteria.
      #   Band.scoped(skip: 10)
      #
      # @note This will force the default scope to be applied.
      #
      # @param [ Hash ] options Query options for the criteria.
      #
      # @option options [ Integer ] :skip Optional number of documents to skip.
      # @option options [ Integer ] :limit Optional number of documents to
      #   limit.
      # @option options [ Array ] :sort Optional sorting options.
      #
      # @return [ Criteria ] A scoped criteria.
      #
      # @since 3.0.0
      def scoped(options = nil)
        queryable.scoped(options)
      end

      # Get the criteria without the default scoping applied.
      #
      # @example Get the unscoped criteria.
      #   Band.unscoped
      #
      # @example Yield to block with no default scoping.
      #   Band.unscoped do
      #     Band.where(name: "Depeche Mode")
      #   end
      #
      # @note This will force the default scope to be removed.
      #
      # @return [ Criteria, Object ] The unscoped criteria or result of the
      #   block.
      #
      # @since 3.0.0
      def unscoped
        if block_given?
          without_default_scope do
            yield(self)
          end
        else
          queryable.unscoped
        end
      end

      # Get a criteria with the default scope applied, if possible.
      #
      # @example Get a criteria with the default scope.
      #   Model.with_default_scope
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 3.0.0
      def with_default_scope
        queryable.with_default_scope
      end
      alias :criteria :with_default_scope

      # Pushes the provided criteria onto the scope stack, and removes it after the
      # provided block is yielded.
      #
      # @example Yield to the criteria.
      #   Person.with_scope(criteria)
      #
      # @param [ Criteria ] criteria The criteria to apply.
      #
      # @return [ Criteria ] The yielded criteria.
      #
      # @since 1.0.0
      def with_scope(criteria)
        scope_stack.push(criteria)
        begin
          yield criteria
        ensure
          scope_stack.pop
        end
      end

      # Execute the block without applying the default scope.
      #
      # @example Execute without the default scope.
      #   Band.without_default_scope do
      #     Band.where(name: "Depeche Mode")
      #   end
      #
      # @return [ Object ] The result of the block.
      #
      # @since 3.0.0
      def without_default_scope
        Threaded.begin_execution("without_default_scope")
        yield
      ensure
        Threaded.exit_execution("without_default_scope")
      end

      private

      # Warns or raises exception if overriding another scope or method.
      #
      # @api private
      #
      # @example Warn or raise error if name exists.
      #   Model.valid_scope_name?("test")
      #
      # @param [ String, Symbol ] name The name of the scope.
      #
      # @raise [ Errors::ScopeOverwrite ] If the name exists and configured to
      #   raise the error.
      #
      # @since 2.1.0
      def check_scope_name(name)
        if scopes[name] || respond_to?(name, true)
          if Mongoid.scope_overwrite_exception
            raise Errors::ScopeOverwrite.new(self.name, name)
          else
            if Mongoid.logger
              Mongoid.logger.warn(
                "Creating scope :#{name}. " +
                "Overwriting existing method #{self.name}.#{name}."
              )
            end
          end
        end
      end

      # Checks if the intended scope is a valid object, either a criteria or
      # proc with a criteria.
      #
      # @api private
      #
      # @example Check if the scope is valid.
      #   Model.check_scope_validity({})
      #
      # @param [ Object ] value The intended scope.
      #
      # @raise [ Errors::InvalidScope ] If the scope is not a valid object.
      #
      # @since 3.0.0
      def check_scope_validity(value)
        unless value.respond_to?(:to_proc)
          raise Errors::InvalidScope.new(self, value)
        end
      end

      # Defines the actual class method that will execute the scope when
      # called.
      #
      # @api private
      #
      # @example Define the scope class method.
      #   Model.define_scope_method(:active)
      #
      # @param [ Symbol ] name The method/scope name.
      #
      # @return [ Method ] The defined method.
      #
      # @since 3.0.0
      def define_scope_method(name)
        (class << self; self; end).class_eval <<-SCOPE
          def #{name}(*args)
            scoping = scopes[:#{name}]
            scope, extension = scoping[:scope][*args], scoping[:extension]
            criteria = with_default_scope.merge(scope || all)
            criteria.extend(extension)
            criteria
          end
        SCOPE
      end

      # Process the default scope value. If one already exists, we merge the
      # new one into the old one.
      #
      # @api private
      #
      # @example Process the default scope.
      #   Model.process_default_scope(value)
      #
      # @param [ Criteria, Proc ] value The default scope value.
      #
      # @since 3.0.5
      def process_default_scope(value)
        if existing = default_scoping
          ->{ existing.call.merge(value.to_proc.call) }
        else
          value.to_proc
        end
      end

      # Strip the default scope from the provided value, if it is a criteria.
      # This is used by named scopes - they should not have the default scoping
      # applied to them.
      #
      # @api private
      #
      # @example Strip the default scope.
      #   Model.strip_default_scope
      #
      # @param [ Proc, Criteria ] value The value to strip from.
      #
      # @return [ Proc ] The stripped criteria, as a proc.
      #
      # @since 3.0.0
      def strip_default_scope(value)
        if value.is_a?(Criteria)
          default = default_scoping.try(:call)
          value.remove_scoping(default)
          value.to_proc
        else
          value
        end
      end
    end
  end
end
