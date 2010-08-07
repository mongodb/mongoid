# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class Many < Relations::Proxy

        # Instantiate a new embeds_many relation.
        #
        # Options:
        #
        # target: The target [child document array] of the relation.
        # metadata: The relation's metadata
        def initialize(target, metadata)
          init(target, metadata)
        end

        # Substitutes the supplied target documents for the existing documents
        # in the relation.
        #
        # Example:
        #
        # <tt>addresses.substitute([ address ])</tt>
        #
        # Options:
        #
        # target: An array of documents to replace the existing docs.
        #
        # Returns:
        #
        # The relation.
        def substitute(target)
          target.nil? ? @target.clear : @target = target; self
        end
      end
    end
  end
end
