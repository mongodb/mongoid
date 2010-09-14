# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class In < Proxy

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # Example:
        #
        # <tt>name.person.bind</tt>
        def bind(building = nil)
          Bindings::Embedded::In.new(base, target, metadata).bind
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
        # other: A document to replace the target.
        #
        # Returns:
        #
        # The relation or nil.
        def substitute(new_target, building = nil)
          # TODO: Durran: One/In susbstitution is identical
          old_target = target
          tap do |relation|
            relation.target = new_target
            new_target ? bind(building) : (unbind(old_target) and return nil)
          end
        end

        # Unbinds the base object to the inverse of the relation. This occurs
        # when setting a side of the relation to nil.
        #
        # Will delete the object if necessary.
        #
        # Example:
        #
        # <tt>name.person.unbind</tt>
        def unbind(old_target)
          Bindings::Embedded::In.new(base, old_target, metadata).unbind
          base.delete if old_target.persisted? && !base.destroyed?
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
