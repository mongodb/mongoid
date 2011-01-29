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
        # @option options [ true, false ] :binding Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def bind(options = {})
          binding.bind(options)
          target.map(&:save) if base.persisted? && !options[:binding]
        end

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # @example Clear the relation.
        #   person.posts.clear
        #
        # @return [ Many ] The relation emptied.
        def clear(options = {})
          load! and tap do |relation|
            relation.unbind(default_options(options))
            target.clear
          end
        end

        # Returns a count of the number of documents in the association that have
        # actually been persisted to the database.
        #
        # Use #size if you want the total number of documents in memory.
        #
        # @example Get the count of persisted documents.
        #   person.posts.count
        #
        # @return [ Integer ] The total number of persisted documents.
        def count
          criteria.count
        end

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted.
        #
        # @example Create and save the new document.
        #   person.posts.create(:text => "Testing")
        #
        # @param [ Hash ] attributes The attributes to create with.
        # @param [ Class ] type The optional type of document to create.
        #
        # @return [ Document ] The newly created document.
        def create(attributes = nil, type = nil)
          build(attributes, type).tap do |doc|
            base.persisted? ? doc.save : raise_unsaved(doc)
          end
        end

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted and will raise an
        # error if validation fails.
        #
        # @example Create and save the new document.
        #   person.posts.create!(:text => "Testing")
        #
        # @param [ Hash ] attributes The attributes to create with.
        # @param [ Class ] type The optional type of document to create.
        #
        # @raise [ Errors::Validations ] If validation failed.
        #
        # @return [ Document ] The newly created document.
        def create!(attributes = nil, type = nil)
          build(attributes, type).tap do |doc|
            base.persisted? ? doc.save! : raise_unsaved(doc)
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
          return criteria.id_criteria(arg) unless arg.is_a?(Symbol)
          criteria.find(arg, :conditions => options[:conditions] || {})
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

        # Will load the target into an array if the target had not already been
        # loaded.
        #
        # @example Load the relation into memory.
        #   relation.load!
        #
        # @return [ Many ] The relation.
        #
        # @since 2.0.0.rc.5
        def load!(options = {})
          tap do |relation|
            unless relation.loaded?
              relation.target = target.entries
              relation.bind(options)
              relation.loaded = true
            end
          end
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
          clear(:binding => true, :continue => true, :nullify => true)
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
        # @option options [ true, false ] :binding Are we in build mode?
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
        # @option options [ true, false ] :binding Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def unbind(options = {})
          binding.unbind(options)
          if base.persisted?
            target.each(&:delete) unless options[:binding]
            target.each(&:save) if options[:nullify]
          end
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
          load!(options) and target.push(document)
          characterize_one(document)
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
          metadata.klass.where(metadata.foreign_key => base.id)
        end

        # If the target array does not respond to the supplied method then try to
        # find a named scope or criteria on the class and send the call there.
        #
        # If the method exists on the array, use the default proxy behavior.
        #
        # @param [ Symbol, String ] name The name of the method.
        # @param [ Array ] args The method args
        # @param [ Proc ] block Optional block to pass.
        #
        # @return [ Criteria, Object ] A Criteria or return value from the target.
        def method_missing(name, *args, &block)
          load!(:binding => true) and return super if [].respond_to?(name)
          klass = metadata.klass
          klass.send(:with_scope, criteria) do
            criteria.send(name, *args)
          end
        end

        # When the base is not yet saved and the user calls create or create!
        # on the relation, this error will get raised.
        #
        # @example Raise the error.
        #   relation.raise_unsaved(post)
        #
        # @param [ Document ] doc The child document getting created.
        #
        # @raise [ Errors::UnsavedDocument ] The error.
        #
        # @since 2.0.0.rc.6
        def raise_unsaved(doc)
          raise Errors::UnsavedDocument.new(base, doc)
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
            Builders::Referenced::Many.new(meta, object || [])
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
