# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:

      # This class defines the behaviour needed for embedded one to one
      # relations.
      class One < Relations::One

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # @example Bind the relation.
        #   person.name.bind(:continue => false)
        #
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :binding Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def bind(options = {})
          binding.bind(options)
          target.save if base.persisted? && !options[:binding]
        end

        # Instantiate a new embeds_one relation.
        #
        # @example Create the new proxy.
        #   One.new(person, name, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Document ] target The child document in the relation.
        # @param [ Metadata ] metadata The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            characterize_one(target)
            target.parentize(base)
          end
        end

        # Unbinds the base object to the inverse of the relation. This occurs
        # when setting a side of the relation to nil.
        #
        # Will delete the object if necessary.
        #
        # @example Unbind the relation.
        #   person.name.unbind(name, :continue => true)
        #
        # @param [ Document ] old_target The previous target of the relation.
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :binding Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def unbind(old_target, options = {})
          binding(old_target).unbind(options)
          old_target.delete if base.persisted? && !old_target.destroyed?
        end

        private

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Document ] new_target The new document to bind with.
        #
        # @return [ Binding ] The relation's binding.
        #
        # @since 2.0.0.rc.1
        def binding(new_target = nil)
          Bindings::Embedded::One.new(base, new_target || target, metadata)
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Embedded::One.builder(meta, object, person)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build with.
          #
          # @return [ Builder ] A newly instantiated builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object)
            Builders::Embedded::One.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # @example Is this relation embedded?
          #   Embedded::One.embedded?
          #
          # @return [ true ] true.
          #
          # @since 2.0.0.rc.1
          def embedded?
            true
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the macro.
          #   Mongoid::Relations::Embedded::One.macro
          #
          # @return [ Symbol ] :embeds_one.
          #
          # @since 2.0.0.rc.1
          def macro
            :embeds_one
          end

          # Return the nested builder that is responsible for generating
          # the documents that will be used by this relation.
          #
          # @example Get the builder.
          #   NestedAttributes::One.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The options for the builder.
          #
          # @option options [ true, false ] :allow_destroy Can documents be
          #   deleted?
          # @option options [ Integer ] :limit Max number of documents to
          #   create at once.
          # @option options [ Proc, Symbol ] :reject_if If documents match this
          #   option then they are ignored.
          # @option options [ true, false ] :update_only Only existing documents
          #   can be modified.
          #
          # @return [ Builder ] A newly instantiated nested builder object.
          #
          # @since 2.0.0.rc.1
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::One.new(metadata, attributes, options)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Embedded::One.stores_foreign_key?
          #
          # @return [ false ] false.
          #
          # @since 2.0.0.rc.1
          def stores_foreign_key?
            false
          end
        end
      end
    end
  end
end
