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
      # other: A document to replace the target.
      #
      # Returns:
      #
      # The relation or nil.
      def substitute(new_target, building = nil)
        old_target = target
        tap do |relation|
          relation.target = new_target
          new_target ? bind(building) : (unbind(old_target) and return nil)
        end
      end
    end
  end
end
