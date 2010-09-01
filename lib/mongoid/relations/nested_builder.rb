# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class NestedBuilder #:nodoc:

      attr_accessor :attributes, :metadata, :options

      def allow_destroy?
        options[:allow_destroy] != false
      end

      def reject_if?
        options[:reject_if]
      end

      def update_only?
        !!options[:update_only]
      end
    end
  end
end
