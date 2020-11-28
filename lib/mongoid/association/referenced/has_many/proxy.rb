# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Referenced
      class HasMany

        # This class defines the behavior for all associations that are a
        # one-to-many between documents in different collections.
        class Proxy < Association::Many
          extend Forwardable

          def_delegator :criteria, :count
          def_delegators :_target, :first, :in_memory, :last, :reset, :uniq

          # Appends a document or array of documents to the association. Will set
          # the parent and update the index in the process.
          #
          # @example Append a document.
          #   person.posts << post
          #
          # @example Push a document.
          #   person.posts.push(post)
          #
          # @example Concat with other documents.
          #   person.posts.concat([ post_one, post_two ])
          #
          # @param [ Document, Array<Document> ] args Any number of documents.
          #
          # @return [ Array<Document> ] The loaded docs.
          #
          # @since 2.0.0.beta.1
          def <<(*args)
            docs = args.flatten
            return concat(docs) if docs.size > 1
            if doc = docs.first
              append(doc)
              doc.save if persistable? && !_assigning? && !doc.validated?
            end
            self
          end

          alias :push :<<

          # Appends an array of documents to the association. Performs a batch
          # insert of the documents instead of persisting one at a time.
          #
          # @example Concat with other documents.
          #   person.posts.concat([ post_one, post_two ])
          #
          # @param [ Array<Document> ] documents The docs to add.
          #
          # @return [ Array<Document> ] The documents.
          #
          # @since 2.4.0
          def concat(documents)
            docs, inserts = [], []
            documents.each do |doc|
              next unless doc
              append(doc)
              save_or_delay(doc, docs, inserts) if persistable?
            end
            persist_delayed(docs, inserts)
            self
          end

          # Build a new document from the attributes and append it to this
          # association without saving.
          #
          # @example Build a new document on the association.
          #   person.posts.build(:title => "A new post")
          #
          # @param [ Hash ] attributes The attributes of the new document.
          # @param [ Class ] type The optional subclass to build.
          #
          # @return [ Document ] The new document.
          #
          # @since 2.0.0.beta.1
          def build(attributes = {}, type = nil)
            doc = Factory.build(type || klass, attributes)
            append(doc)
            doc.apply_post_processed_defaults
            yield(doc) if block_given?
            doc.run_callbacks(:build) { doc }
            doc
          end

          alias :new :build

          # Delete the document from the association. This will set the foreign key
          # on the document to nil. If the dependent options on the association are
          # :delete_all or :destroy the appropriate removal will occur.
          #
          # @example Delete the document.
          #   person.posts.delete(post)
          #
          # @param [ Document ] document The document to remove.
          #
          # @return [ Document ] The matching document.
          #
          # @since 2.1.0
          def delete(document)
            execute_callback :before_remove, document
            _target.delete(document) do |doc|
              if doc
                unbind_one(doc)
                cascade!(doc) if !_assigning?
              end
              execute_callback :after_remove, doc
            end
          end

          # Deletes all related documents from the database given the supplied
          # conditions.
          #
          # @example Delete all documents in the association.
          #   person.posts.delete_all
          #
          # @example Conditonally delete all documents in the association.
          #   person.posts.delete_all({ :title => "Testing" })
          #
          # @param [ Hash ] conditions Optional conditions to delete with.
          #
          # @return [ Integer ] The number of documents deleted.
          #
          # @since 2.0.0.beta.1
          def delete_all(conditions = nil)
            remove_all(conditions, :delete_all)
          end

          # Destroys all related documents from the database given the supplied
          # conditions.
          #
          # @example Destroy all documents in the association.
          #   person.posts.destroy_all
          #
          # @example Conditonally destroy all documents in the association.
          #   person.posts.destroy_all({ :title => "Testing" })
          #
          # @param [ Hash ] conditions Optional conditions to destroy with.
          #
          # @return [ Integer ] The number of documents destroyd.
          #
          # @since 2.0.0.beta.1
          def destroy_all(conditions = nil)
            remove_all(conditions, :destroy_all)
          end

          # Iterate over each document in the association and yield to the provided
          # block.
          #
          # @note This will load the entire association into memory.
          #
          # @example Iterate over the documents.
          #   person.posts.each do |post|
          #     post.save
          #   end
          #
          # @return [ Array<Document> ] The loaded docs.
          #
          # @since 2.1.0
          def each
            if block_given?
              _target.each { |doc| yield(doc) }
            else
              to_enum
            end
          end

          # Determine if any documents in this association exist in the database.
          #
          # If the association contains documents but all of the documents
          # exist only in the application, i.e. have not been persisted to the
          # database, this method returns false.
          #
          # This method queries the database on each invocation even if the
          # association is already loaded into memory.
          #
          # @example Are there persisted documents?
          #   person.posts.exists?
          #
          # @return [ true, false ] True is persisted documents exist, false if not.
          def exists?
            criteria.exists?
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
          # @note This will keep matching documents in memory for iteration
          #   later.
          #
          # @param [ BSON::ObjectId, Array<BSON::ObjectId> ] args The ids.
          #
          # @return [ Document, Criteria ] The matching document(s).
          #
          # @since 2.0.0.beta.1
          def find(*args)
            matching = criteria.find(*args)
            Array(matching).each { |doc| _target.push(doc) }
            matching
          end

          # Instantiate a new references_many association. Will set the foreign key
          # and the base on the inverse object.
          #
          # @example Create the new association.
          #   Referenced::Many.new(base, target, association)
          #
          # @param [ Document ] base The document this association hangs off of.
          # @param [ Array<Document> ] target The target of the association.
          # @param [ Association ] association The association metadata.
          #
          # @since 2.0.0.beta.1
          def initialize(base, target, association)
            enum = HasMany::Enumerable.new(target, base, association)
            init(base, enum, association) do
              raise_mixed if klass.embedded? && !klass.cyclic?
            end
          end

          # Removes all associations between the base document and the target
          # documents by deleting the foreign keys and the references, orphaning
          # the target documents in the process.
          #
          # @example Nullify the association.
          #   person.posts.nullify
          #
          # @since 2.0.0.rc.1
          def nullify
            criteria.update_all(foreign_key => nil)
            _target.clear do |doc|
              unbind_one(doc)
              doc.changed_attributes.delete(foreign_key)
            end
          end

          alias :nullify_all :nullify

          # Clear the association. Will delete the documents from the db if they are
          # already persisted.
          #
          # @example Clear the association.
          #   person.posts.clear
          #
          # @return [ Many ] The association emptied.
          #
          # @since 2.0.0.beta.1
          def purge
            unless _association.destructive?
              nullify
            else
              after_remove_error = nil
              criteria.delete_all
              many = _target.clear do |doc|
                execute_callback :before_remove, doc
                unbind_one(doc)
                doc.destroyed = true
                begin
                  execute_callback :after_remove, doc
                rescue => e
                  after_remove_error = e
                end
              end
              raise after_remove_error if after_remove_error
              many
            end
          end

          alias :clear :purge

          # Substitutes the supplied target documents for the existing documents
          # in the association. If the new target is nil, perform the necessary
          # deletion.
          #
          # @example Replace the association.
          #   person.posts.substitute([ new_post ])
          #
          # @param [ Array<Document> ] replacement The replacement target.
          #
          # @return [ Many ] The association.
          #
          # @since 2.0.0.rc.1
          def substitute(replacement)
            if replacement
              new_docs, docs = replacement.compact, []
              new_ids = new_docs.map { |doc| doc._id }
              remove_not_in(new_ids)
              new_docs.each do |doc|
                docs.push(doc) if doc.send(foreign_key) != _base.send(_association.primary_key)
              end
              concat(docs)
            else
              purge
            end
            self
          end

          # Get a criteria for the documents without the default scoping
          # applied.
          #
          # @example Get the unscoped criteria.
          #   person.posts.unscoped
          #
          # @return [ Criteria ] The unscoped criteria.
          #
          # @since 2.4.0
          def unscoped
            klass.unscoped.where(foreign_key => _base.send(_association.primary_key))
          end

          private

          # Appends the document to the target array, updating the index on the
          # document at the same time.
          #
          # @example Append the document to the association.
          #   relation.append(document)
          #
          # @param [ Document ] document The document to append to the target.
          #
          # @since 2.0.0.rc.1
          def append(document)
            with_add_callbacks(document, already_related?(document)) do
              _target.push(document)
              characterize_one(document)
              bind_one(document)
            end
          end

          # Execute before/after add callbacks around the block unless the objects
          # already have a persisted association.
          #
          # @example Execute before/after add callbacks around the block.
          #   relation.with_add_callbacks(document, false)
          #
          # @param [ Document ] document The document to append to the target.
          # @param [ true, false ] already_related Whether the document is already related
          #   to the target.
          #
          # @since 5.1.0
          def with_add_callbacks(document, already_related)
            execute_callback :before_add, document unless already_related
            yield
            execute_callback :after_add, document unless already_related
          end

          # Whether the document and the base already have a persisted association.
          #
          # @example Is the document already related to the base.
          #   relation.already_related?(document)
          #
          # @param [ Document ] document The document to possibly append to the target.
          #
          # @return [ true, false ] Whether the document is already related to the base and the
          #   association is persisted.
          #
          # @since 5.1.0
          def already_related?(document)
            document.persisted? &&
                document._association &&
                document.respond_to?(document._association.foreign_key) &&
                document.__send__(document._association.foreign_key) == _base._id
          end

          # Instantiate the binding associated with this association.
          #
          # @example Get the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The binding.
          #
          # @since 2.0.0.rc.1
          def binding
            HasMany::Binding.new(_base, _target, _association)
          end

          # Get the collection of the association in question.
          #
          # @example Get the collection of the association.
          #   relation.collection
          #
          # @return [ Collection ] The collection of the association.
          #
          # @since 2.0.2
          def collection
            klass.collection
          end

          # Returns the criteria object for the target class with its documents set
          # to target.
          #
          # @example Get a criteria for the association.
          #   relation.criteria
          #
          # @return [ Criteria ] A new criteria.
          #
          # @since 2.0.0.beta.1
          def criteria
            @criteria ||= _association.criteria(_base)
          end

          # Perform the necessary cascade operations for documents that just got
          # deleted or nullified.
          #
          # @example Cascade the change.
          #   relation.cascade!(document)
          #
          # @param [ Document ] document The document to cascade on.
          #
          # @return [ true, false ] If the association is destructive.
          #
          # @since 2.1.0
          def cascade!(document)
            if persistable?
              case _association.dependent
              when :delete_all
                document.delete
              when :destroy
                document.destroy
              else
                document.save
              end
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
          #
          # @since 2.0.0.beta.1
          def method_missing(name, *args, &block)
            if _target.respond_to?(name)
              _target.send(name, *args, &block)
            else
              klass.send(:with_scope, criteria) do
                criteria.public_send(name, *args, &block)
              end
            end
          end

          # Persist all the delayed batch inserts.
          #
          # @api private
          #
          # @example Persist the delayed batch inserts.
          #   relation.persist_delayed([ doc ])
          #
          # @param [ Array<Document> ] docs The delayed inserts.
          # @param [ Array<Hash> ] inserts The raw insert document.
          #
          # @since 3.0.0
          def persist_delayed(docs, inserts)
            unless docs.empty?
              collection.insert_many(inserts, session: _session)
              docs.each do |doc|
                doc.new_record = false
                doc.run_after_callbacks(:create, :save) unless _association.autosave?
                doc.post_persist
              end
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
            !_binding? && (_creating? || _base.persisted? && !_building?)
          end

          # Deletes all related documents from the database given the supplied
          # conditions.
          #
          # @example Delete all documents in the association.
          #   person.posts.delete_all
          #
          # @example Conditonally delete all documents in the association.
          #   person.posts.delete_all({ :title => "Testing" })
          #
          # @param [ Hash ] conditions Optional conditions to delete with.
          # @param [ Symbol ] method The deletion method to call.
          #
          # @return [ Integer ] The number of documents deleted.
          #
          # @since 2.1.0
          def remove_all(conditions = nil, method = :delete_all)
            selector = conditions || {}
            removed = klass.send(method, selector.merge!(criteria.selector))
            _target.delete_if do |doc|
              if doc._matches?(selector)
                unbind_one(doc) and true
              end
            end
            removed
          end

          # Remove all the documents in the proxy that do not have the provided
          # ids.
          #
          # @example Remove all documents without the ids.
          #   proxy.remove_not_in([ id ])
          #
          # @param [ Array<Object> ] ids The ids.
          #
          # @since 2.4.0
          def remove_not_in(ids)
            removed = criteria.not_in(_id: ids)
            if _association.destructive?
              removed.delete_all
            else
              removed.update_all(foreign_key => nil)
            end
            in_memory.each do |doc|
              if !ids.include?(doc._id)
                unbind_one(doc)
                _target.delete(doc)
                if _association.destructive?
                  doc.destroyed = true
                end
              end
            end
          end

          # Save a persisted document immediately or delay a new document for
          # batch insert.
          #
          # @api private
          #
          # @example Save or delay the document.
          #   relation.save_or_delay(doc, [])
          #
          # @param [ Document ] doc The document.
          # @param [ Array<Document> ] inserts The inserts.
          #
          # @since 3.0.0
          def save_or_delay(doc, docs, inserts)
            if doc.new_record? && doc.valid?(:create)
              doc.run_before_callbacks(:save, :create)
              docs.push(doc)
              inserts.push(doc.send(:as_attributes))
            else
              doc.save
            end
          end

          class << self

            def eager_loader(association, docs)
              Eager.new(association, docs)
            end

            # Returns true if the association is an embedded one. In this case
            # always false.
            #
            # @example Is this association embedded?
            #   Referenced::Many.embedded?
            #
            # @return [ false ] Always false.
            #
            # @since 2.0.0.rc.1
            def embedded?
              false
            end
          end
        end
      end
    end
  end
end
