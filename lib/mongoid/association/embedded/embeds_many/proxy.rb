# frozen_string_literal: true

require 'mongoid/association/embedded/batchable'

module Mongoid
  module Association
    module Embedded
      class EmbedsMany
        # Transparent proxy for embeds_many associations.
        # An instance of this class is returned when calling the
        # association getter method on the parent document. This
        # class inherits from Mongoid::Association::Proxy and forwards
        # most of its methods to the target of the association, i.e.
        # the array of child documents.
        class Proxy < Association::Many
          include Batchable

          # Class-level methods for the Proxy class.
          module ClassMethods
            # Returns the eager loader for this association.
            #
            # @param [ Array<Mongoid::Association> ] associations The
            #   associations to be eager loaded
            # @param [ Array<Mongoid::Document> ] docs The parent documents
            #   that possess the given associations, which ought to be
            #   populated by the eager-loaded documents.
            #
            # @return [ Mongoid::Association::Embedded::Eager ]
            def eager_loader(associations, docs)
              Eager.new(associations, docs)
            end

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

          extend ClassMethods

          # Instantiate a new embeds_many association.
          #
          # @example Create the new association.
          #   Many.new(person, addresses, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Array<Document> ] target The child documents of the association.
          # @param [ Mongoid::Association::Relatable ] association The association metadata.
          #
          # @return [ Many ] The proxy.
          def initialize(base, target, association)
            super do
              _target.each_with_index do |doc, index|
                integrate(doc)
                doc._index = index
              end
              update_attributes_hash
              @_unscoped = _target.dup
              @_target = scope(_target)
            end
          end

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
            return unless docs.any?
            return concat(docs) if docs.size > 1

            docs.first.tap do |doc|
              append(doc)
              doc.save if persistable? && !_assigning?
            end

            self
          end

          alias push <<

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
            Factory.execute_build(type || _association.klass, attributes, execute_callbacks: false).tap do |doc|
              append(doc)
              doc.apply_post_processed_defaults
              yield doc if block_given?
              doc.run_pending_callbacks
              doc.run_callbacks(:build) { doc }
              _base._reset_memoized_descendants!
            end
          end

          alias new build

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

            _target.count(&:persisted?)
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
              _target.delete_one(document).tap do |doc|
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
              end
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
          # @return [ EmbedsMany::Proxy | Enumerator ] The proxy or an
          #   enumerator if no block was provided.
          def delete_if
            return super unless block_given?

            _target.dup.each { |doc| delete(doc) if yield doc }

            self
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
          # @param [ :none | nil | false | Hash | Object ] id_or_conditions
          #   When :none (the default), returns true if any persisted
          #   documents exist in the association. When nil or false, this
          #   will always return false. When a Hash is given, this queries
          #   the documents in the association for those that match the given
          #   conditions, and returns true if any match which have been
          #   persisted. Any other argument is interpreted as an id, and
          #   queries for the existence of persisted documents in the
          #   association with a matching _id.
          #
          # @return [ true | false ] True if persisted documents exist, false if not.
          def exists?(id_or_conditions = :none)
            case id_or_conditions
            when :none then _target.any?(&:persisted?)
            when nil, false then false
            when Hash then where(id_or_conditions).any?(&:persisted?)
            else where(_id: id_or_conditions).any?(&:persisted?)
            end
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
          # @param &block Optional block to pass.
          # @yield [ Object ] Yields each enumerable element to the block.
          #
          # @return [ Document | Array<Document> | nil ] A document or matching documents.
          def find(...)
            criteria.find(...)
          end

          # Get all the documents in the association that are loaded into memory.
          #
          # @example Get the in memory documents.
          #   relation.in_memory
          #
          # @return [ Array<Document> ] The documents in memory.
          alias in_memory _target

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
          # @return [ Document | Array<Document> | nil ] The popped document(s).
          def pop(count = nil)
            return [] if count&.zero?

            docs = _target.last(count || 1).each { |doc| delete(doc) }
            (count.nil? || docs.empty?) ? docs.first : docs
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
          # @return [ Document | Array<Document> | nil ] The shifted document(s).
          def shift(count = nil)
            return [] if count&.zero?

            docs = _target.first(count || 1).each { |doc| delete(doc) }
            (count.nil? || docs.empty?) ? docs.first : docs
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

          attr_accessor :_unscoped

          def object_already_related?(document)
            _target.any? { |existing| existing._id && existing == document }
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
            _target.push(*scope([ document ])) unless object_already_related?(document)
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
          # @param &block Optional block to pass.
          #
          # @return [ Criteria | Object ] A Criteria or return value from the target.
          #
          # TODO: make sure we are consistingly using respond_to_missing
          #   anywhere we define method_missing.
          # rubocop:disable Style/MissingRespondToMissing
          ruby2_keywords def method_missing(name, *args, &block)
            return super if _target.respond_to?(name)

            klass.send(:with_scope, criteria) do
              criteria.public_send(name, *args, &block)
            end
          end
          # rubocop:enable Style/MissingRespondToMissing

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
            return docs unless _association.order || _association.klass.default_scoping?

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
            criteria.size.tap do
              batch_remove(criteria, method)
              update_attributes_hash
            end
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
            if _target.empty?
              _base.attributes.delete(_association.store_as)
            else
              _base.attributes.merge!(_association.store_as => _target.map(&:attributes))
            end
          end
        end
      end
    end
  end
end
