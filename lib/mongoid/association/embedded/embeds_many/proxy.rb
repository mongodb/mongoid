# frozen_string_literal: true

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
          # @param [ Document... ] *args Any number of documents.
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
            doc = Factory.execute_build(type || _association.klass, attributes, execute_callbacks: false)
            append(doc)
            doc.apply_post_processed_defaults
            yield(doc) if block_given?
            doc.run_pending_callbacks
            doc.run_callbacks(:build) { doc }
            _base._reset_memoized_descendants!
            doc
          end

          alias :new :build

          # Clear the association. Will delete the documents from the db
          # if they are already persisted.
          #
          # If the host document is not persisted but its _id matches a
          # persisted document, calling #clear on an association will remove
          # the association's documents from the database even though the
          # set of documents in the application (as loaded in the host)
          # is different from what is in the database, and the host may
          # not contain any persisted documents in the association either.
          #
          # @example Clear the association.
          #   person.addresses.clear
          #
          # @return [ self ] The empty association.
          def clear
            batch_clear(_target.dup)
            update_attributes_hash
            self
          end

          # Returns a count of the number of documents in the association that have
          # actually been persisted to the database.
          #
          # Use #size if you want the total number of documents.
          #
          # If args or block are present, #count will delegate to the
          # #count method on +target+ and will include both persisted
          # and non-persisted documents.
          #
          # @example Get the count of persisted documents.
          #   person.addresses.count
          #
          # @example Get the count of all documents matching a block.
          #   person.addresses.count { |a| a.country == "FR" }
          #
          # @example Use #persisted? inside block to count persisted documents.
          #   person.addresses.count { |a| a.persisted? && a.country == "FR" }
          #
          # @param [ Object... ] *args Args to delegate to the target.
          #
          # @return [ Integer ] The total number of persisted embedded docs, as
          #   flagged by the #persisted? method.
          def count(*args, &block)
            return _target.count(*args, &block) if args.any? || block

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
          # @return [ Document | nil ] The deleted document or nil if nothing deleted.
          def delete(document)
            execute_callbacks_around(:remove, document) do
              doc = _target.delete_one(document)
              if doc && !_binding?
                _unscoped.delete_one(doc)
                if _assigning?
                  _base.add_atomic_pull(doc)
                else
                  doc.delete(suppress: true)
                  unbind_one(doc)
                end
                update_attributes_hash
              end
              reindex
              doc
            end
          end

          # Mongoid::Extensions::Array defines Array#delete_one, so we need
          # to make sure that method behaves reasonably on proxies, too.
          alias delete_one delete

          # Removes a single document from the collection *in memory only*.
          # It will *not* persist the change.
          #
          # @param [ Document ] document The document to delete.
          #
          # @api private
          def _remove(document)
            _target.delete_one(document)
            _unscoped.delete_one(document)
            update_attributes_hash
            reindex
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
          # @return [ Many | Enumerator ] The association or an enumerator if no
          #   block was provided.
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
          # @return [ true | false ] True is persisted documents exist, false if not.
          def exists?
            _target.any? { |doc| doc.persisted? }
          end

          # Finds a document in this association through several different
          # methods.
          #
          # This method delegates to +Mongoid::Criteria#find+. If this method is
          # not given a block, it returns one or many documents for the provided
          # _id values.
          #
          # If this method is given a block, it returns the first document
          # of those found by the current Criteria object for which the block
          # returns a truthy value.
          #
          # @example Find a document by its id.
          #   person.addresses.find(BSON::ObjectId.new)
          #
          # @example Find documents for multiple ids.
          #   person.addresses.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
          #
          # @example Finds the first matching document using a block.
          #   person.addresses.find { |addr| addr.state == 'CA' }
          #
          # @param [ Object... ] *args Various arguments.
          # @param [ Proc ] block Optional block to pass.
          #
          # @return [ Document | Array<Document> | nil ] A document or matching documents.
          def find(*args, &block)
            criteria.find(*args, &block)
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
              update_attributes_hash
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
          # @return [ Document | Array<Document> ] The popped document(s).
          def pop(count = nil)
            if count
              if docs = _target[_target.size - count, _target.size]
                docs.each { |doc| delete(doc) }
              end
            else
              delete(_target[-1])
            end.tap do
              update_attributes_hash
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
          # @return [ Document | Array<Document> ] The shifted document(s).
          def shift(count = nil)
            if count
              if _target.size > 0 && docs = _target[0, count]
                docs.each { |doc| delete(doc) }
              end
            else
              delete(_target[0])
            end.tap do
              update_attributes_hash
            end
          end

          # Substitutes the supplied target documents for the existing documents
          # in the relation.
          #
          # @example Substitute the association's target.
          #   person.addresses.substitute([ address ])
          #
          # @param [ Array<Document> | Array<Hash> ] docs The replacement docs.
          #
          # @return [ Many ] The proxied association.
          def substitute(docs)
            batch_replace(docs)
            update_attributes_hash
            self
          end

          # Return the association with all previous scoping removed. This is the
          # exact representation of the docs in the database.
          #
          # @example Get the unscoped documents.
          #   person.addresses.unscoped
          #
          # @return [ Criteria ] The unscoped association.
          def unscoped
            criterion = klass.unscoped
            criterion.embedded = true
            criterion.documents = _unscoped.delete_if(&:marked_for_destruction?)
            criterion
          end

          private

          def object_already_related?(document)
            _target.any? { |existing| existing._id && existing === document }
          end

          # Appends the document to the target array, updating the index on the
          # document at the same time.
          #
          # @example Append to the document.
          #   relation.append(document)
          #
          # @param [ Document ] document The document to append to the target.
          def append(document)
            execute_callback :before_add, document
            unless object_already_related?(document)
              _target.push(*scope([document]))
            end
            _unscoped.push(document)
            integrate(document)
            update_attributes_hash
            document._index = _unscoped.size - 1
            execute_callback :after_add, document
          end

          # Instantiate the binding associated with this association.
          #
          # @example Create the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The many binding.
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

          # Integrate the document into the association. will set its metadata and
          # attempt to bind the inverse.
          #
          # @example Integrate the document.
          #   relation.integrate(document)
          #
          # @param [ Document ] document The document to integrate.
          def integrate(document)
            characterize_one(document)
            bind_one(document)
          end

          # If the target array does not respond to the supplied method then try to
          # find a named scope or criteria on the class and send the call there.
          #
          # If the method exists on the array, use the default proxy behavior.
          #
          # @param [ Symbol | String ] name The name of the method.
          # @param [ Object... ] *args The method args.
          # @param [ Proc ] block Optional block to pass.
          #
          # @return [ Criteria | Object ] A Criteria or return value from the target.
          ruby2_keywords def method_missing(name, *args, &block)
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
          # @return [ true | false ] If the association is persistable.
          def persistable?
            _base.persisted? && !_binding?
          end

          # Reindex all the target elements. This is useful when performing
          # operations on the proxied target directly and the indices need to
          # match that on the database side.
          #
          # @example Reindex the association.
          #   person.addresses.reindex
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
          # @param [ true | false ] method :delete or :destroy.
          #
          # @return [ Integer ] The number of documents removed.
          def remove_all(conditions = {}, method = :delete)
            criteria = where(conditions || {})
            removed = criteria.size
            batch_remove(criteria, method)
            update_attributes_hash
            removed
          end

          # Get the internal unscoped documents.
          #
          # @example Get the unscoped documents.
          #   relation._unscoped
          #
          # @return [ Array<Document> ] The unscoped documents.
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
          def _unscoped=(docs)
            @_unscoped = docs
          end

          # Returns a list of attributes hashes for each document.
          #
          # @return [ Array<Hash> ] The list of attributes hashes
          def as_attributes
            _unscoped.map { |doc| doc.send(:as_attributes) }
          end

          # Update the _base's attributes hash with the _target's attributes
          #
          # @api private
          def update_attributes_hash
            if !_target.empty?
              _base.attributes.merge!(_association.store_as => _target.map(&:attributes))
            else
              _base.attributes.delete(_association.store_as)
            end
          end

          class << self

            # Returns true if the association is an embedded one. In this case
            # always true.
            #
            # @example Is the association embedded?
            #   Association::Embedded::EmbedsMany.embedded?
            #
            # @return [ true ] true.
            def embedded?
              true
            end

            # Returns the suffix of the foreign key field, either "_id" or "_ids".
            #
            # @example Get the suffix for the foreign key.
            #   Association::Embedded::EmbedsMany.foreign_key_suffix
            #
            # @return [ nil ] nil.
            def foreign_key_suffix
              nil
            end
          end
        end
      end
    end
  end
end
