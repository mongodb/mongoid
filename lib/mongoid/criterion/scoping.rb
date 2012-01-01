# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Scoping

      attr_accessor :default_scopable

      # Apply the model's default scope to this criteria.
      #
      # @example Apply the default scope.
      #   criteria.apply_default_scope
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 2.4.0
      def apply_default_scope
        if klass.default_scoping && default_scopable?
          self.default_scopable = false
          fuse(klass.default_scoping)
        else
          self
        end
      end

      # Is the default scope of the class allowed to be applied?
      #
      # @example Can the default scope be applied?
      #   criteria.default_scopable?
      #
      # @return [ true, false ] The the default can be applied.
      #
      # @since 2.4.0
      def default_scopable?
        default_scopable != false
      end

      # Force the default scope to be applied to the criteria.
      #
      # @example Force default scoping.
      #   criteria.scoped
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 2.4.0
      def scoped
        self.default_scopable = true
        apply_default_scope
      end

      # Get the criteria with the default scoping removed.
      #
      # @note This has slightly different behaviour than AR - will remove the
      #   default scoping if no other criteria have been chained and tampered
      #   with the criterion instead of clearing everything.
      #
      # @example Get the criteria unscoped.
      #   criteria.unscoped
      #
      # @return [ Criteria ] The unscoped criteria.
      #
      # @since 2.4.0
      def unscoped
        clone.tap do |criteria|
          criteria.clear_scoping
          criteria.default_scopable = false
        end
      end

      # Remove all scoping from the criteria.
      #
      # @example Remove the default scope.
      #   criteria.clear_scoping
      #
      # @return [ nil ] No guaranteed return value.
      #
      # @since 2.4.0
      def clear_scoping
        selector.clear
        options.clear
      end
    end
  end
end
