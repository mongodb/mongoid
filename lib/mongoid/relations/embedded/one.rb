# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class One < Proxy

        def bind
        end

        # Instantiate a new embeds_one relation.
        #
        # Options:
        #
        # base: The document this relation hangs off of.
        # target: The target [child document] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            target.parentize(base)
          end
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
          tap do |relation|
            relation.target = target
            target.parentize(base)
            metadatafy(target)
          end
        end

        def unbind
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Embedded::One.builder(meta, object, person)</tt>
          #
          # Options:
          #
          # meta: The metadata of the relation.
          # object: A document or attributes to build with.
          #
          # Returns:
          #
          # A newly instantiated builder object.
          def builder(meta, object)
            Builders::Embedded::One.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # Example:
          #
          # <tt>Embedded::One.embedded?</tt>
          #
          # Returns:
          #
          # true
          def embedded?
            true
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Embedded::One.macro</tt>
          #
          # Returns:
          #
          # <tt>:embeds_one</tt>
          def macro
            :embeds_one
          end
        end
      end
    end
  end
end
