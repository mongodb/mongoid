# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:

      # This class defines the behaviour for all relations that are a
      # one-to-one between documents in different collections.
      class One < Relations::One

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # @example Bind the relation.
        #   person.game.bind(:continue => false)
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

        # Instantiate a new references_one relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # @example Create the new relation.
        #   Referenced::One.new(base, target, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Document ] target The target (child) of the relation.
        # @param [ Metadata ] metadata The relation's metadata.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            characterize_one(target)
          end
        end

        # Will load the target into an array if the target had not already been
        # loaded.
        #
        # @example Load the relation into memory.
        #   relation.load!
        #
        # @return [ One ] The relation.
        #
        # @since 2.0.0.rc.5
        def load!(options = {})
          raise_mixed if klass.embedded?
          super(options)
        end

        # Removes the association between the base document and the target
        # document by deleting the foreign key and the reference, orphaning
        # the target document in the process.
        #
        # @example Nullify the relation.
        #   person.game.nullify
        #
        # @since 2.0.0.rc.1
        def nullify
          target.send(metadata.foreign_key_setter, nil)
          target.send(:remove_instance_variable, "@#{metadata.inverse(target)}")
          base.send(:remove_instance_variable, "@#{metadata.name}")
          target.save
        end

        # Unbinds the base object to the inverse of the relation. This occurs
        # when setting a side of the relation to nil.
        #
        # Will delete the object if necessary.
        #
        # @example Unbind the relation.
        #   person.game.unbind(name, :continue => true)
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
          if base.persisted? && !old_target.destroyed? && !options[:binding]
            old_target.delete
          end
        end

        private

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Document ] new_target The new target of the relation.
        #
        # @return [ Binding ] The binding object.
        def binding(new_target = nil)
          Bindings::Referenced::One.new(base, new_target || target, metadata)
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::One.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object)
            Builders::Referenced::One.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::One.embedded?
          #
          # @return [ false ] Always false.
          #
          # @since 2.0.0.rc.1
          def embedded?
            false
          end

          # Get the default value for the foreign key.
          #
          # @example Get the default.
          #   Referenced::One.foreign_key_default
          #
          # @return [ nil ] Always nil.
          #
          # @since 2.0.0.rc.1
          def foreign_key_default
            nil
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # @example Get the suffix for the foreign key.
          #   Referenced::One.foreign_key_suffix
          #
          # @return [ String ] "_id"
          #
          # @since 2.0.0.rc.1
          def foreign_key_suffix
            "_id"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the macro.
          #   Referenced::One.macro
          #
          # @return [ Symbol ] :references_one.
          def macro
            :references_one
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::One.builder(attributes, options)
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
          # @return [ NestedBuilder ] A newly instantiated nested builder object.
          #
          # @since 2.0.0.rc.1
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::One.new(metadata, attributes, options)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Referenced::One.stores_foreign_key?
          #
          # @return [ false ] Always false.
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
