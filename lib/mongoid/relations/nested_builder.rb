# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class NestedBuilder #:nodoc:

      attr_accessor :attributes, :existing, :metadata, :options

      # Determines if destroys are allowed for this document.
      #
      # Example:
      #
      # <tt>one.allow_destroy?</tt>
      #
      # Returns:
      #
      # True if the allow destroy option was set.
      def allow_destroy?
        options[:allow_destroy] || false
      end

      # Returns the reject if option defined with the macro.
      #
      # Example:
      #
      # <tt>reject_if?</tt>
      #
      # Returns:
      #
      # True if rejectable.
      def reject?(attrs)
        criteria = options[:reject_if]
        criteria ? criteria.call(attrs) : false
      end

      # Determines if only updates can occur. Only valid for one-to-one
      # relations.
      #
      # Example:
      #
      # <tt>one.update_only?</tt>
      #
      # Returns:
      #
      # True if the update_only option was set.
      def update_only?
        options[:update_only] || false
      end
    end
  end
end
