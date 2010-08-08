# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class OneToOne < Proxy

      # Substitutes the supplied target documents for the existing document
      # in the relation.
      #
      # Example:
      #
      # <tt>name.substitute(new_name)</tt>
      #
      # Options:
      #
      # target: A document to replace the target.
      #
      # Returns:
      #
      # The relation or nil.
      def substitute(target)
        return nil unless target
        @target = target
        self
      end
    end
  end
end
