# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class In < Proxy

        def bind
          inverse = metadata.inverse(target)
          base.metadata = target.class.reflect_on_association(inverse)
        end

        # Instantiate a new embedded_in relation.
        #
        # Options:
        #
        # base: The document the relation hangs off of.
        # target: The target [parent document] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            base.parentize(target)
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
          @target = target
          self
        end

        def unbind

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
            Builders::Embedded::In.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # Example:
          #
          # <tt>Embedded::In.embedded?</tt>
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
          # <tt>Mongoid::Relations::Embedded::In.macro</tt>
          #
          # Returns:
          #
          # <tt>:embedded_in</tt>
          def macro
            :embedded_in
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>NestedAttributes::One.builder(attributes, options)</tt>
          #
          # Options:
          #
          # attributes: The attributes to build with.
          # options: The options for the builder.
          #
          # Returns:
          #
          # A newly instantiated nested builder object.
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::One.new(metadata, attributes, options)
          end
        end
      end
    end
  end
end
