# encoding: utf-8
module Mongoid
  class Criteria
    module Scopable

      # Applies the default scope to the criteria.
      #
      # @example Apply the default scope.
      #   criteria.apply_default_scope
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 3.0.0
      def apply_default_scope
        klass.without_default_scope do
          merge!(klass.default_scoping.call)
        end
        self.scoping_options = true, false
      end

      # Given another criteria, remove the other criteria's scoping from this
      # criteria.
      #
      # @example Remove the scoping.
      #   criteria.remove_scoping(other)
      #
      # @param [ Criteria ] other The other criteria.
      #
      # @return [ Criteria ] The criteria with scoping removed.
      #
      # @since 3.0.0
      def remove_scoping(other)
        if other
          reject_matching(other, :selector, :options)
          other.inclusions.each do |meta|
            inclusions.delete_one(meta)
          end
        end
        self
      end

      # Forces the criteria to be scoped, unless its inside an unscoped block.
      #
      # @example Force the criteria to be scoped.
      #   criteria.scoped(skip: 10)
      #
      # @param [ Hash ] options Additional query options.
      #
      # @return [ Criteria ] The scoped criteria.
      #
      # @since 3.0.0
      def scoped(options = nil)
        crit = clone
        crit.options.merge!(options || {})
        if klass.default_scopable? && !scoped?
          crit.apply_default_scope
        end
        crit
      end

      # Has the criteria had the default scope applied?
      #
      # @example Is the default scope applied?
      #   criteria.scoped?
      #
      # @return [ true, false ] If the default scope is applied.
      #
      # @since 3.0.0
      def scoped?
        !!(defined?(@scoped) ? @scoped : nil)
      end

      # Clears all scoping from the criteria.
      #
      # @example Clear all scoping from the criteria.
      #   criteria.unscoped
      #
      # @return [ Criteria ] The unscoped criteria.
      #
      # @since 3.0.0
      def unscoped
        crit = clone
        unless unscoped?
          crit.scoping_options = false, true
          crit.selector.clear; crit.options.clear
        end
        crit
      end

      # Is the criteria unscoped?
      #
      # @example Is the criteria unscoped?
      #   criteria.unscoped?
      #
      # @return [ true, false ] If the criteria is force unscoped.
      #
      # @since 3.0.0
      def unscoped?
        !!(defined?(@unscoped) ? @unscoped : nil)
      end

      # Get the criteria scoping options, as a pair (scoped, unscoped).
      #
      # @example Get the scoping options.
      #   criteria.scoping_options
      #
      # @return [ Array ] Scoped, unscoped.
      #
      # @since 3.0.0
      def scoping_options
        [ (defined?(@scoped) ? @scoped : nil), (defined?(@unscoped) ? @unscoped : nil) ]
      end

      # Set the criteria scoping options, as a pair (scoped, unscoped).
      #
      # @example Set the scoping options.
      #   criteria.scoping_options = true, false
      #
      # @param [ Array ] options Scoped, unscoped.
      #
      # @return [ Array ] The new scoping options.
      #
      # @since 3.0.0
      def scoping_options=(options)
        @scoped, @unscoped = options
      end

      # Get the criteria with the default scope applied, if the default scope
      # is able to be applied. Cases in which it cannot are: If we are in an
      # unscoped block, if the criteria is already forced unscoped, or the
      # default scope has already been applied.
      #
      # @example Get the criteria with the default scope.
      #   criteria.with_default_scope
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 3.0.0
      def with_default_scope
        crit = clone
        if klass.default_scopable? && !unscoped? && !scoped?
          crit.apply_default_scope
        end
        crit
      end

      private

      def reject_matching(other, *methods)
        methods.each do |method|
          send(method).reject! do |key, value|
            other.send(method).has_key?(key) && other.send(method)[key] == value
          end
        end
      end
    end
  end
end
