# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:
      class One < Proxy

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # Example:
        #
        # <tt>person.game.bind</tt>
        def bind
          Bindings::Referenced::One.new(base, target, metadata).bind
          target.save if base.persisted?
        end

        # Instantiate a new references_one relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # Example:
        #
        # <tt>Referenced::One.new(base, target, metadata)</tt>
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
        # in the relation. If the new target is nil, perform the necessary
        # deletion.
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
          target.tap { |t| t ? (@target = t and bind) : unbind }
        end

        # Unbinds the base object to the inverse of the relation. This occurs
        # when setting a side of the relation to nil.
        #
        # Will delete the object if necessary.
        #
        # Example:
        #
        # <tt>person.game.unbind</tt>
        def unbind
          Bindings::Referenced::One.new(base, target, metadata).unbind
          target.delete if base.persisted?
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Referenced::One.builder(meta, object)</tt>
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
            Builders::Referenced::One.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # Example:
          #
          # <tt>Referenced::One.embedded?</tt>
          #
          # Returns:
          #
          # true
          def embedded?
            false
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # Example:
          #
          # <tt>Referenced::One.foreign_key_suffix</tt>
          #
          # Returns:
          #
          # "_id"
          def foreign_key_suffix
            "_id"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Referenced::One.macro</tt>
          #
          # Returns:
          #
          # <tt>:references_one</tt>
          def macro
            :references_one
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # Example:
          #
          # <tt>Referenced::One.stores_foreign_key?</tt>
          #
          # Returns:
          #
          # false
          def stores_foreign_key?
            false
          end
        end
      end
    end
  end
end
