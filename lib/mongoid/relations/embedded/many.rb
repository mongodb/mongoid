# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded #:nodoc:

      # This class handles the behaviour for a document that embeds many other
      # documents within in it as an array.
      class Many < Relations::Many
        include Atomic

        # Appends a document or array of documents to the relation. Will set
        # the parent and update the index in the process.
        #
        # @example Append a document.
        #   person.addresses << address
        #
        # @example Push a document.
        #   person.addresses.push(address)
        #
        # @example Concat with other documents.
        #   person.addresses.concat([ address_one, address_two ])
        #
        # @param [ Document, Array<Document> ] *args Any number of documents.
        def <<(*args)
          options = default_options(args)
          atomically(:$pushAll) do
            args.flatten.each do |doc|
              return doc unless doc
              append(doc, options)
              doc.save if base.persisted? && !options[:binding]
            end
          end
        end

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # @example Bind the relation.
        #   person.addresses.bind(:continue => true)
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
          if base.persisted? && !options[:binding]
            atomically(:$set) { target.each(&:save) }
          end
        end

        # Bind the inverse relation between a single document in this proxy
        # instead of the entire target.
        #
        # Used when appending to the target instead of setting the entire
        # thing.
        #
        # @example Bind a single document.
        #   person.addressses.bind_one(address)
        #
        # @param [ Document ] document The document to bind.
        #
        # @since 2.0.0.rc.1
        def bind_one(document, options = {})
          binding.bind_one(document, options)
        end

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # @example Clear the relation.
        #   person.addresses.clear
        #
        # @return [ Many ] The empty relation.
        def clear
          load! and substitute(nil)
        end

        # Returns a count of the number of documents in the association that have
        # actually been persisted to the database.
        #
        # Use #size if you want the total number of documents.
        #
        # @example Get the count of persisted documents.
        #   person.addresses.count
        #
        # @return [ Integer ] The total number of persisted embedded docs, as
        #   flagged by the #persisted? method.
        def count
          target.select(&:persisted?).size
        end

        # Create a new document in the relation. This is essentially the same
        # as doing a #build then #save on the new document.
        #
        # @example Create a new document in the relation.
        #   person.movies.create(:name => "Bozo")
        #
        # @param [ Hash ] attributes The attributes to build the document with.
        # @param [ Class ] type Optional class to create the document with.
        #
        # @return [ Document ] The newly created document.
        def create(attributes = {}, type = nil, &block)
          build(attributes, type, &block).tap(&:save)
        end

        # Create a new document in the relation. This is essentially the same
        # as doing a #build then #save on the new document. If validation
        # failed on the document an error will get raised.
        #
        # @example Create the document.
        #   person.addresses.create!(:street => "Unter der Linden")</tt>
        #
        # @param [ Hash ] attributes The attributes to build the document with.
        # @param [ Class ] type Optional class to create the document with.
        #
        # @raise [ Errors::Validations ] If a validation error occured.
        #
        # @return [ Document ] The newly created document.
        def create!(attributes = {}, type = nil, &block)
          build(attributes, type, &block).tap(&:save!)
        end

        # Delete the supplied document from the target. This method is proxied
        # in order to reindex the array after the operation occurs.
        #
        # @example Delete the document from the relation.
        #   person.addresses.delete(address)
        #
        # @param [ Document ] document The document to be deleted.
        #
        # @return [ Document, nil ] The deleted document or nil if nothing deleted.
        #
        # @since 2.0.0.rc.1
        def delete(document)
          target.delete(document).tap { reindex }
        end

        # Delete all the documents in the association without running callbacks.
        #
        # @example Delete all documents from the relation.
        #   person.addresses.delete_all
        #
        # @example Conditionally delete documents from the relation.
        #   person.addresses.delete_all(:conditions => { :street => "Bond" })
        #
        # @param [ Hash ] conditions Conditions on which documents to delete.
        #
        # @return [ Integer ] The number of documents deleted.
        def delete_all(conditions = {})
          atomically(:$pull) { remove_all(conditions, :delete) }
        end

        # Destroy all the documents in the association whilst running callbacks.
        #
        # @example Destroy all documents from the relation.
        #   person.addresses.destroy_all
        #
        # @example Conditionally destroy documents from the relation.
        #   person.addresses.destroy_all(:conditions => { :street => "Bond" })
        #
        # @param [ Hash ] conditions Conditions on which documents to destroy.
        #
        # @return [ Integer ] The number of documents destroyed.
        def destroy_all(conditions = {})
          atomically(:$pull) { remove_all(conditions, :destroy) }
        end

        # Finds a document in this association through several different
        # methods.
        #
        # @example Find a document by its id.
        #   person.addresses.find(BSON::ObjectId.new)
        #
        # @example Find documents for multiple ids.
        #   person.addresses.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
        #
        # @example Find documents based on conditions.
        #   person.addresses.find(:all, :conditions => { :number => 10 })
        #   person.addresses.find(:first, :conditions => { :number => 10 })
        #   person.addresses.find(:last, :conditions => { :number => 10 })
        #
        # @param [ Array<Object> ] args Various arguments.
        #
        # @return [ Array<Document>, Document ] A single or multiple documents.
        def find(*args)
          criteria.find(*args)
        end

        # Instantiate a new embeds_many relation.
        #
        # @example Create the new relation.
        #   Many.new(person, addresses, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Array<Document> ] target The child documents of the relation.
        # @param [ Metadata ] metadata The relation's metadata
        #
        # @return [ Many ] The proxy.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            target.each_with_index do |doc, index|
              characterize_one(doc)
              doc.parentize(base)
              doc._index = index
            end
          end
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
              relation.bind(options)
              relation.loaded = true
            end
          end
        end

        # Paginate the association. Will create a new criteria, set the documents
        # on it and execute in an enumerable context.
        #
        # @example Paginate the relation.
        #   person.addresses.paginate(:page => 1, :per_page => 20)
        #
        # @param [ Hash ] options The pagination options.
        #
        # @option options [ Integer ] :page The page number.
        # @option options [ Integer ] :per_page The number on each page.
        #
        # @return [ WillPaginate::Collection ] The paginated documents.
        def paginate(options)
          criteria.paginate(options)
        end

        # Substitutes the supplied target documents for the existing documents
        # in the relation.
        #
        # @example Substitute the relation's target.
        #   person.addresses.substitute([ address ])
        #
        # @param [ Array<Document> ] new_target The replacement array.
        # @param [ true, false ] building Are we in build mode?
        #
        # @return [ Many ] The proxied relation.
        #
        # @since 2.0.0.rc.1
        def substitute(new_target, options = {})
          old_target = target
          tap do |relation|
            relation.target = new_target || []
            if !new_target.blank?
              atomically(:$set) { rebind(old_target, options) }
            else
              atomically(:$unset) { unbind(old_target, options) }
            end
          end
        end

        # Get this relation as as its representation in the database.
        #
        # @example Convert the relation to an attributes hash.
        #   person.addresses.as_document
        #
        # @return [ Array<Hash> ] The relation as stored in the db.
        #
        # @since 2.0.0.rc.1
        def as_document
          target.inject([]) do |attributes, doc|
            attributes.tap do |attr|
              attr << doc.as_document
            end
          end
        end

        # Unbind the inverse relation from this set of documents. Used when the
        # entire proxy has been cleared, set to nil or empty, or replaced.
        #
        # @example Unbind the relation.
        #   person.addresses.unbind(target, :continue => false)
        #
        # @param [ Array<Document> ] old_target The relations previous target.
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :binding Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def unbind(old_target, options = {})
          binding(old_target).unbind(options)
          if base.persisted?
            old_target.each do |doc|
              doc.delete unless doc.destroyed?
            end
          end
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # @example Append to the document.
        #   relation.append(document)
        #
        # @param [ Document ] document The document to append to the target.
        #
        # @since 2.0.0.rc.1
        def append(document, options = {})
          load! and target.push(document)
          characterize_one(document)
          bind_one(document, options)
          document._index = target.size - 1
        end

        # Instantiate the binding associated with this relation.
        #
        # @example Create the binding.
        #   relation.binding([ address ])
        #
        # @param [ Array<Document> ] new_target The new documents to bind with.
        #
        # @return [ Binding ] The many binding.
        #
        # @since 2.0.0.rc.1
        def binding(new_target = nil)
          Bindings::Embedded::Many.new(base, new_target || target, metadata)
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        def criteria
          metadata.klass.criteria(true).tap do |criterion|
            criterion.documents = target
          end
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
          load!(:binding => true) and return super if target.respond_to?(name)
          klass = metadata.klass
          klass.send(:with_scope, criteria) do
            criteria.send(name, *args)
          end
        end

        # Reindex all the target elements. This is useful when performing
        # operations on the proxied target directly and the indices need to
        # match that on the database side.
        #
        # @example Reindex the relation.
        #   person.addresses.reindex
        #
        # @since 2.0.0.rc.1
        def reindex
          target.each_with_index do |doc, index|
            doc._index = index
          end
        end

        # Remove all documents from the relation, either with a delete or a
        # destroy depending on what this was called through.
        #
        # @example Destroy documents from the relation.
        #   relation.remove_all(:conditions => { :num => 1 }, true)
        #
        # @param [ Hash ] conditions Conditions to filter by.
        # @param [ true, false ] destroy If true then destroy, else delete.
        #
        # @return [ Integer ] The number of documents removed.
        def remove_all(conditions = {}, method = :delete)
          criteria = find(:all, conditions || {})
          criteria.size.tap do
            criteria.each do |doc|
              target.delete(doc)
              doc.send(method, :suppress => true)
            end
            reindex
          end
        end

        # Convenience method to clean up the substitute code. Unbinds the old
        # target and reindexes.
        #
        # @example Rebind the relation.
        #   relation.rebind([])
        #
        # @param [ Array<Document> ] old_target The old target.
        # @param [ Hash ] options The options passed to substitute.
        #
        # @since 2.0.0
        def rebind(old_target, options)
          reindex
          unbind(old_target, options)
          bind(options)
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Embedded::Many.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A newly instantiated builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object)
            Builders::Embedded::Many.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # @example Is the relation embedded?
          #   Embedded::Many.embedded?
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
          # @example Get the relation macro.
          #   Mongoid::Relations::Embedded::Many.macro
          #
          # @return [ Symbol ] :embeds_many
          #
          # @since 2.0.0.rc.1
          def macro
            :embeds_many
          end

          # Return the nested builder that is responsible for generating the
          # documents that will be used by this relation.
          #
          # @example Get the nested builder.
          #   NestedAttributes::Many.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The builder options.
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
          # @return [ NestedBuilder ] The nested attributes builder.
          #
          # @since 2.0.0.rc.1
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::Many.new(metadata, attributes, options)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Embedded::Many.stores_foreign_key?
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
