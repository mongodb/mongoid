# frozen_string_literal: true
# encoding: utf-8

require 'mongoid/association/embedded/batchable'

module Mongoid
  module Association
    module Embedded
      class EmbedsMany

        class Proxy < Association::Many
          include Batchable

          # Appends a document or array of documents to the association. Will set
          # the parent and update the index in the process.
          #
          # @example Append a document.
          #   person.addresses << address
          #
          # @example Push a document.
          #   person.addresses.push(address)
          #
          # @param [ Document, Array<Document> ] args Any number of documents.
          def <<(*args)
            docs = args.flatten
            return concat(docs) if docs.size > 1
            if doc = docs.first
              append(doc)
              doc.save if persistable? && !_assigning?
            end
            self
          end

          alias :push :<<

          # Get this association as as its representation in the database.
          #
          # @example Convert the association to an attributes hash.
          #   person.addresses.as_document
          #
          # @return [ Array<Hash> ] The association as stored in the db.
          #
          # @since 2.0.0.rc.1
          def as_document
            as_attributes.collect { |attrs| BSON::Document.new(attrs) }
          end

          # Appends an array of documents to the association. Performs a batch
          # insert of the documents instead of persisting one at a time.
          #
          # @example Concat with other documents.
          #   person.addresses.concat([ address_one, address_two ])
          #
          # @param [ Array<Document> ] docs The docs to add.
          #
          # @return [ Array<Document> ] The documents.
          #
          # @since 2.4.0
          def concat(docs)
            batch_insert(docs) unless docs.empty?
            self
          end

          # Builds a new document in the association and appends it to the target.
          # Takes an optional type if you want to specify a subclass.
          #
          # @example Build a new document on the association.
          #   person.people.build(:name => "Bozo")
          #
          # @param [ Hash ] attributes The attributes to build the document with.
          # @param [ Class ] type Optional class to build the document with.
          #
          # @return [ Document ] The new document.
          def build(attributes = {}, type = nil)
            doc = Factory.build(type || _association.klass, attributes)
            append(doc)
            doc.apply_post_processed_defaults
            yield(doc) if block_given?
            doc.run_callbacks(:build) { doc }
            _base._reset_memoized_children!
            doc
          end

          alias :new :build

          # Clear the association. Will delete the documents from the db if they are
          # already persisted.
          #
          # @example Clear the association.
          #   person.addresses.clear
          #
          # @return [ self ] The empty association.
          def clear
            batch_clear(_target.dup)
            self
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
            _target.select { |doc| doc.persisted? }.size
          end

          # Delete the supplied document from the target. This method is proxied
          # in order to reindex the array after the operation occurs.
          #
          # @example Delete the document from the association.
          #   person.addresses.delete(address)
          #
          # @param [ Document ] document The document to be deleted.
          #
          # @return [ Document, nil ] The deleted document or nil if nothing deleted.
          #
          # @since 2.0.0.rc.1
          def delete(document)
            execute_callback :before_remove, document
            doc = _target.delete_one(document)
            if doc && !_binding?
              _unscoped.delete_one(doc)
              if _assigning?
                _base.add_atomic_pull(doc)
              else
                doc.delete(suppress: true)
                unbind_one(doc)
              end
            end
            reindex
            execute_callback :after_remove, document
            doc
          end

          # Delete all the documents in the association without running callbacks.
          #
          # @example Delete all documents from the association.
          #   person.addresses.delete_all
          #
          # @example Conditionally delete documents from the association.
          #   person.addresses.delete_all({ :street => "Bond" })
          #
          # @param [ Hash ] conditions Conditions on which documents to delete.
          #
          # @return [ Integer ] The number of documents deleted.
          def delete_all(conditions = {})
            remove_all(conditions, :delete)
          end

          # Delete all the documents for which the provided block returns true.
          #
          # @example Delete the matching documents.
          #   person.addresses.delete_if do |doc|
          #     doc.state == "GA"
          #   end
          #
          # @return [ Many, Enumerator ] The association or an enumerator if no
          #   block was provided.
          #
          # @since 3.1.0
          def delete_if
            if block_given?
              dup_target = _target.dup
              dup_target.each do |doc|
                delete(doc) if yield(doc)
              end
              self
            else
              super
            end
          end

          # Destroy all the documents in the association whilst running callbacks.
          #
          # @example Destroy all documents from the association.
          #   person.addresses.destroy_all
          #
          # @example Conditionally destroy documents from the association.
          #   person.addresses.destroy_all({ :street => "Bond" })
          #
          # @param [ Hash ] conditions Conditions on which documents to destroy.
          #
          # @return [ Integer ] The number of documents destroyed.
          def destroy_all(conditions = {})
            remove_all(conditions, :destroy)
          end

          # Determine if any documents in this association exist in the database.
          #
          # @example Are there persisted documents?
          #   person.posts.exists?
          #
          # @return [ true, false ] True is persisted documents exist, false if not.
          def exists?
            count > 0
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
          # @param [ Array<Object> ] args Various arguments.
          #
          # @return [ Array<Document>, Document ] A single or multiple documents.
          def find(*args)
            criteria.find(*args)
          end

          # Instantiate a new embeds_many association.
          #
          # @example Create the new association.
          #   Many.new(person, addresses, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Array<Document> ] target The child documents of the association.
          # @param [ Association ] association The association metadata
          #
          # @return [ Many ] The proxy.
          def initialize(base, target, association)
            init(base, target, association) do
              _target.each_with_index do |doc, index|
                integrate(doc)
                doc._index = index
              end
              @_unscoped = _target.dup
              @_target = scope(_target)
            end
          end

          # Get all the documents in the association that are loaded into memory.
          #
          # @example Get the in memory documents.
          #   relation.in_memory
          #
          # @return [ Array<Document> ] The documents in memory.
          #
          # @since 2.1.0
          def in_memory
            _target
          end

          # Pop documents off the association. This can be a single document or
          # multiples, and will automatically persist the changes.
          #
          # @example Pop a single document.
          #   relation.pop
          #
          # @example Pop multiple documents.
          #   relation.pop(3)
          #
          # @param [ Integer ] count The number of documents to pop, or 1 if not
          #   provided.
          #
          # @return [ Document, Array<Document> ] The popped document(s).
          #
          # @since 3.0.0
          def pop(count = nil)
            if count
              if docs = _target[_target.size - count, _target.size]
                docs.each { |doc| delete(doc) }
              end
            else
              delete(_target[-1])
            end
          end

          # Shift documents off the association. This can be a single document or
          # multiples, and will automatically persist the changes.
          #
          # @example Shift a single document.
          #   relation.shift
          #
          # @example Shift multiple documents.
          #   relation.shift(3)
          #
          # @param [ Integer ] count The number of documents to shift, or 1 if not
          #   provided.
          #
          # @return [ Document, Array<Document> ] The shifted document(s).
          def shift(count = nil)
            if count
              if _target.size > 0 && docs = _target[0, count]
                docs.each { |doc| delete(doc) }
              end
            else
              delete(_target[0])
            end
          end

          # Substitutes the supplied target documents for the existing documents
          # in the relation.
          #
          # @example Substitute the association's target.
          #   person.addresses.substitute([ address ])
          #
          # @param [ Array<Document> ] docs The replacement docs.
          #
          # @return [ Many ] The proxied association.
          #
          # @since 2.0.0.rc.1
          def substitute(docs)
            batch_replace(docs)
            self
          end

          # Return the association with all previous scoping removed. This is the
          # exact representation of the docs in the database.
          #
          # @example Get the unscoped documents.
          #   person.addresses.unscoped
          #
          # @return [ Criteria ] The unscoped association.
          #
          # @since 2.4.0
          def unscoped
            criterion = klass.unscoped
            criterion.embedded = true
            criterion.documents = _unscoped.delete_if(&:marked_for_destruction?)
            criterion
          end

          private

          def object_already_related?(document)
            _target.any? { |existing| existing.id && existing === document }
          end

          # Appends the document to the target array, updating the index on the
          # document at the same time.
          #
          # @example Append to the document.
          #   relation.append(document)
          #
          # @param [ Document ] document The document to append to the target.
          #
          # @since 2.0.0.rc.1
          def append(document)
            execute_callback :before_add, document
            unless object_already_related?(document)
              _target.push(*scope([document]))
            end
            _unscoped.push(document)
            integrate(document)
            document._index = _unscoped.size - 1
            execute_callback :after_add, document
          end

          # Instantiate the binding associated with this association.
          #
          # @example Create the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The many binding.
          #
          # @since 2.0.0.rc.1
          def binding
            Binding.new(_base, _target, _association)
          end

          # Returns the +Criteria+ object for the target class with its
          # documents set to the list of target documents in the association.
          #
          # @return [ Criteria ] A new criteria.
          def criteria
            _association.criteria(_base, _target)
          end

          # Deletes one document from the target and unscoped.
          #
          # @api private
          #
          # @example Delete one document.
          #   relation.delete_one(doc)
          #
          # @param [ Document ] document The document to delete.
          #
          # @since 2.4.7
          def delete_one(document)
            _target.delete_one(document)
            _unscoped.delete_one(document)
            reindex
          end

          # Integrate the document into the association. will set its metadata and
          # attempt to bind the inverse.
          #
          # @example Integrate the document.
          #   relation.integrate(document)
          #
          # @param [ Document ] document The document to integrate.
          #
          # @since 2.1.0
          def integrate(document)
            characterize_one(document)
            bind_one(document)
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
            return super if _target.respond_to?(name)
            klass.send(:with_scope, criteria) do
              criteria.public_send(name, *args, &block)
            end
          end

          # Are we able to persist this association?
          #
          # @example Can we persist the association?
          #   relation.persistable?
          #
          # @return [ true, false ] If the association is persistable.
          #
          # @since 2.1.0
          def persistable?
            _base.persisted? && !_binding?
          end

          # Reindex all the target elements. This is useful when performing
          # operations on the proxied target directly and the indices need to
          # match that on the database side.
          #
          # @example Reindex the association.
          #   person.addresses.reindex
          #
          # @since 2.0.0.rc.1
          def reindex
            _unscoped.each_with_index do |doc, index|
              doc._index = index
            end
          end

          # Apply the association ordering and default scoping (defined on
          # association's target class) to the provided documents.
          #
          # @example Apply scoping.
          #   person.addresses.scope(target)
          #
          # @param [ Array<Document> ] docs The documents to scope.
          #
          # @return [ Array<Document> ] The scoped docs.
          #
          # @since 2.4.0
          def scope(docs)
            unless _association.order || _association.klass.default_scoping?
              return docs
            end

            crit = _association.klass.order_by(_association.order)
            crit.embedded = true
            crit.documents = docs
            crit.entries
          end

          # Remove all documents from the association, either with a delete or a
          # destroy depending on what this was called through.
          #
          # @example Destroy documents from the association.
          #   relation.remove_all({ :num => 1 }, true)
          #
          # @param [ Hash ] conditions Conditions to filter by.
          # @param [ true, false ] method :delete or :destroy.
          #
          # @return [ Integer ] The number of documents removed.
          def remove_all(conditions = {}, method = :delete)
            criteria = where(conditions || {})
            removed = criteria.size
            batch_remove(criteria, method)
            removed
          end

          # Get the internal unscoped documents.
          #
          # @example Get the unscoped documents.
          #   relation._unscoped
          #
          # @return [ Array<Document> ] The unscoped documents.
          #
          # @since 2.4.0
          def _unscoped
            @_unscoped ||= []
          end

          # Set the internal unscoped documents.
          #
          # @example Set the unscoped documents.
          #   relation._unscoped = docs
          #
          # @param [ Array<Document> ] docs The documents.
          #
          # @return [ Array<Document ] The unscoped docs.
          #
          # @since 2.4.0
          def _unscoped=(docs)
            @_unscoped = docs
          end

          def as_attributes
            attributes = []
            _unscoped.each do |doc|
              attributes.push(doc.as_document)
            end
            attributes
          end

          class << self

            # Returns true if the association is an embedded one. In this case
            # always true.
            #
            # @example Is the association embedded?
            #   Association::Embedded::EmbedsMany.embedded?
            #
            # @return [ true ] true.
            #
            # @since 2.0.0.rc.1
            def embedded?
              true
            end

            # Returns the suffix of the foreign key field, either "_id" or "_ids".
            #
            # @example Get the suffix for the foreign key.
            #   Association::Embedded::EmbedsMany.foreign_key_suffix
            #
            # @return [ nil ] nil.
            #
            # @since 3.0.0
            def foreign_key_suffix
              nil
            end
          end
        end
      end
    end
  end
end
