# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class In < Proxy

        # Instantiate a new embedded_in relation.
        #
        # Options:
        #
        # base: The document the relation hangs off of.
        # target: The target [parent document] of the relation.
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
          @target = target
          self
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Embedded::In.builder(meta, object, person)</tt>
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
            Builders::In.new(meta, object)
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Embedded::In.macro</tt>
          #
          # Returns:
          #
          # <tt>:embedded_in</tt>
          def macro
            :embedded_in
          end
        end
      end
    end
  end
end
