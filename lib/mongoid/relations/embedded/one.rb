# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class One < Relations::Proxy

        # Instantiate a new embeds_one relation.
        #
        # Options:
        #
        # base: The document this relation hangs off of.
        # target: The target [child document] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata)
        end

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
          @target = target; self
        end
      end
    end
  end
end
