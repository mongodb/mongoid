# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class One < OneToOne

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
          # parent: Optional parent relation.
          #
          # Returns:
          #
          # A newly instantiated builder object.
          def builder(meta, object, parent = nil)
            Builders::One.new(meta, object, parent)
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
