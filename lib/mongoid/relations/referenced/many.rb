# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:

      # This class defines the behaviour for all relations that are a
      # one-to-many between documents in different collections.
      class Many < Relations::Many

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # @example Bind the relation.
        #   person.posts.bind
        #
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :building Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def bind(options = {})
          binding.bind(options)
          target.map(&:save) if base.persisted? && !options[:building]
        end

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # @example Clear the relation.
        #   person.posts.clear
        #
        # @return [ Many ] The relation emptied.
        def clear
          tap do |relation|
            relation.unbind(default_options)
            target.clear
          end
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # @example Delete all documents in the relation.
        #   person.posts.delete_all
        #
        # @example Conditonally delete all documents in the relation.
        #   person.posts.delete_all(:conditions => { :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to delete with.
        #
        # @return [ Integer ] The number of documents deleted.
        def delete_all(conditions = nil)
          selector = (conditions || {})[:conditions] || {}
          target.delete_if { |doc| doc.matches?(selector) }
          metadata.klass.delete_all(
            :conditions => selector.merge(metadata.foreign_key => base.id)
          )
        end

        # Destroys all related documents from the database given the supplied
        # conditions.
        #
        # @example Destroy all documents in the relation.
        #   person.posts.destroy_all
        #
        # @example Conditonally destroy all documents in the relation.
        #   person.posts.destroy_all(:conditions => { :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to destroy with.
        #
        # @return [ Integer ] The number of documents destroyd.
        def destroy_all(conditions = nil)
          selector = (conditions || {})[:conditions] || {}
          target.delete_if { |doc| doc.matches?(selector) }
          metadata.klass.destroy_all(
            :conditions => selector.merge(metadata.foreign_key => base.id)
          )
        end

        # Find the matchind document on the association, either based on id or
        # conditions.
        #
        # @example Find by an id.
        #   person.posts.find(BSON::ObjectId.new)
        #
        # @example Find by multiple ids.
        #   person.posts.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
        #
        # @example Conditionally find all matching documents.
        #   person.posts.find(:all, :conditions => { :title => "Sir" })
        #
        # @example Conditionally find the first document.
        #   person.posts.find(:first, :conditions => { :title => "Sir" })
        #
        # @example Conditionally find the last document.
        #   person.posts.find(:last, :conditions => { :title => "Sir" })
        #
        # @param [ Symbol, BSON::ObjectId, Array<BSON::ObjectId> ] arg The
        #   argument to search with.
        # @param [ Hash ] options The options to search with.
        #
        # @return [ Document, Criteria ] The matching document(s).
        def find(arg, options = {})
          klass = metadata.klass
          return klass.criteria.id_criteria(arg) unless arg.is_a?(Symbol)
          selector = (options[:conditions] || {}).merge(
            metadata.foreign_key => base.id
          )
          klass.find(arg, :conditions => selector)
        end

        # Instantiate a new references_many relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # @example Create the new relation.
        #   Referenced::Many.new(base, target, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Array<Document> ] target The target of the relation.
        # @param [ Metadata ] metadata The relation's metadata.
        def initialize(base, target, metadata)
          init(base, target, metadata)
        end

        # Removes all associations between the base document and the target
        # documents by deleting the foreign keys and the references, orphaning
        # the target documents in the process.
        #
        # @example Nullify the relation.
        #   person.posts.nullify
        #
        # @since 2.0.0.rc.1
        def nullify
          loaded and target.each do |doc|
            doc.send(metadata.foreign_key_setter, nil)
            doc.send(
              :remove_instance_variable, "@#{metadata.inverse(doc)}"
            )
            doc.save
          end
        end
        alias :nullify_all :nullify

        # Substitutes the supplied target documents for the existing documents
        # in the relation. If the new target is nil, perform the necessary
        # deletion.
        #
        # @example Replace the relation.
        #   person.posts.substitute(new_name)
        #
        # @param [ Array<Document> ] target The replacement target.
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :building Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @return [ Many ] The relation.
        #
        # @since 2.0.0.rc.1
        def substitute(target, options = {})
          tap { target ? (@target = target.to_a; bind(options)) : (@target = unbind(options)) }
        end

        # Unbinds the base object to the inverse of the relation. This occurs
        # when setting a side of the relation to nil.
        #
        # Will delete the object if necessary.
        #
        # @example Unbind the target.
        #   person.posts.unbind
        #
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :building Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def unbind(options = {})
          binding.unbind(options)
          target.each(&:delete) if base.persisted?
          []
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # @example Append the document to the relation.
        #   relation.append(document)
        #
        # @param [ Document ] document The document to append to the target.
        #
        # @since 2.0.0.rc.1
        def append(document, options = {})
          loaded and target.push(document)
          metadatafy(document)
          binding.bind_one(document, options)
        end

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Array<Document> ] new_target The new documents to bind with.
        #
        # @return [ Binding ] The binding.
        #
        # @since 2.0.0.rc.1
        def binding(new_target = nil)
          Bindings::Referenced::Many.new(base, new_target || target, metadata)
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        def criteria
          metadata.klass.criteria(false)
        end

        # Will load the target into an array if the target had not already been
        # loaded.
        #
        # @example Load the relation into memory.
        #   relation.loaded
        #
        # @return [ Many ] The relation.
        #
        # @since 2.0.0.rc.1
        def loaded
          tap do |relation|
            relation.target = target.entries if target.is_a?(Mongoid::Criteria)
          end
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::Many.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object)
            Builders::Referenced::Many.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::Many.embedded?
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
          #   Referenced::Many.foreign_key_default
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
          #   Referenced::Many.foreign_key_suffix
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
          #   Referenced::Many.macro
          #
          # @return [ Symbol ] :references_many
          def macro
            :references_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::Many.builder(attributes, options)
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
            Builders::NestedAttributes::Many.new(metadata, attributes, options)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Referenced::Many.stores_foreign_key?
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
