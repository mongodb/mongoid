# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Embedded

      # Contains behavior for executing operations in batch on embedded
      # documents.
      module Batchable
        include Positional

        # Insert new documents as a batch push ($push with $each). This ensures that
        # all callbacks are run at the appropriate time and only 1 request is
        # made to the database.
        #
        # @example Execute the batch push.
        #   batchable.batch_insert([ doc_one, doc_two ])
        #
        # @param [ Array<Document> ] docs The docs to add.
        #
        # @return [ Array<Hash> ] The inserts.
        #
        # @since 3.0.0
        def batch_insert(docs)
          execute_batch_push(docs)
        end

        # Clear all of the docs out of the association in a single swipe.
        #
        # @example Clear all docs.
        #   batchable.batch_clear(docs)
        #
        # @param [ Array<Document> ] docs The docs to clear.
        #
        # @return [ Array ] The empty array.
        #
        # @since 3.0.0
        def batch_clear(docs)
          pre_process_batch_remove(docs, :delete)
          unless docs.empty?
            collection.find(selector).update_one(
                positionally(selector, "$unset" => { path => true }),
                session: _session
            )
            post_process_batch_remove(docs, :delete)
          end
          _unscoped.clear
        end

        # Batch remove the provided documents as a $pullAll.
        #
        # @example Batch remove the documents.
        #   batchable.batch_remove([ doc_one, doc_two ])
        #
        # @param [ Array<Document> ] docs The docs to remove.
        # @param [ Symbol ] method Delete or destroy.
        #
        # @since 3.0.0
        def batch_remove(docs, method = :delete)
          removals = pre_process_batch_remove(docs, method)
          if !docs.empty?
            collection.find(selector).update_one(
                positionally(selector, "$pullAll" => { path => removals }),
                session: _session
            )
            post_process_batch_remove(docs, method)
          end
          reindex
        end

        # Batch replace the provided documents as a $set.
        #
        # @example Batch replace the documents.
        #   batchable.batch_replace([ doc_one, doc_two ])
        #
        # @param [ Array<Document> ] docs The docs to replace with.
        #
        # @return [ Array<Hash> ] The inserts.
        #
        # @since 3.0.0
        def batch_replace(docs)
          if docs.blank?
            if _assigning? && !empty?
              _base.add_atomic_unset(first)
              target_duplicate = _target.dup
              pre_process_batch_remove(target_duplicate, :delete)
              post_process_batch_remove(target_duplicate, :delete)
            else
              batch_remove(_target.dup)
            end
          elsif _target != docs
            _base.delayed_atomic_sets.clear unless _assigning?
            docs = normalize_docs(docs).compact
            _target.clear and _unscoped.clear
            inserts = execute_batch_set(docs)
            add_atomic_sets(inserts)
          end
        end

        private

        # Add the atomic sets to the base document.
        #
        # @api private
        #
        # @example Add the atomic sets.
        #   batchable.add_atomic_sets([{ field: value }])
        #
        # @param [ Array<Hash> ] sets The atomic sets.
        #
        # @since 3.0.0
        def add_atomic_sets(sets)
          if _assigning?
            _base.delayed_atomic_sets[path].try(:clear)
            _base.collect_children.each do |child|
              child.delayed_atomic_sets.clear
            end
            _base.delayed_atomic_sets[path] = sets
          end
        end

        # Perform a batch persist of the provided documents with a $set.
        #
        # @api private
        #
        # @example Perform a batch $set.
        #   batchable.execute_batch_set(docs)
        #
        # @param [ Array<Document> ] docs The docs to persist.
        #
        # @return [ Array<Hash> ] The inserts.
        #
        # @since 7.0.0
        def execute_batch_set(docs)
          self.inserts_valid = true
          inserts = pre_process_batch_insert(docs)
          if insertable?
            collection.find(selector).update_one(
                positionally(selector, '$set' => { path => inserts }),
                session: _session
            )
            post_process_batch_insert(docs)
          end
          inserts
        end

        # Perform a batch persist of the provided documents with $push and $each.
        #
        # @api private
        #
        # @example Perform a batch push.
        #   batchable.execute_batch_push(docs)
        #
        # @param [ Array<Document> ] docs The docs to persist.
        #
        # @return [ Array<Hash> ] The inserts.
        #
        # @since 7.0.0
        def execute_batch_push(docs)
          self.inserts_valid = true
          pushes = pre_process_batch_insert(docs)
          if insertable?
            collection.find(selector).update_one(
                positionally(selector, '$push' => { path => { '$each' => pushes } }),
                session: _session
            )
            post_process_batch_insert(docs)
          end
          pushes
        end

        # Are we in a state to be able to batch insert?
        #
        # @api private
        #
        # @example Can inserts be performed?
        #   batchable.insertable?
        #
        # @return [ true, false ] If inserts can be performed.
        #
        # @since 3.0.0
        def insertable?
          persistable? && !_assigning? && inserts_valid
        end

        # Are the inserts currently valid?
        #
        # @api private
        #
        # @example Are the inserts currently valid.
        #   batchable.inserts_valid
        #
        # @return [ true, false ] If inserts are currently valid.
        #
        # @since 3.0.0
        def inserts_valid
          @inserts_valid
        end

        # Set the inserts valid flag.
        #
        # @api private
        #
        # @example Set the flag.
        #   batchable.inserts_valid = true
        #
        # @param [ true, false ] value The flag.
        #
        # @return [ true, false ] The flag.
        #
        # @since 3.0.0
        def inserts_valid=(value)
          @inserts_valid = value
        end

        # Normalize the documents, in case they were provided as an array of
        # hashes.
        #
        # @api private
        #
        # @example Normalize the docs.
        #   batchable.normalize_docs(docs)
        #
        # @param [ Array<Hash, Document> ] docs The docs to normalize.
        #
        # @return [ Array<Document> ] The docs.
        #
        # @since 3.0.0
        def normalize_docs(docs)
          if docs.first.is_a?(::Hash)
            docs.map do |doc|
              attributes = { _association: _association, _parent: _base }
              attributes.merge!(doc)
              Factory.build(klass, attributes)
            end
          else
            docs
          end
        end

        # Get the atomic path.
        #
        # @api private
        #
        # @example Get the atomic path.
        #   batchable.path
        #
        # @return [ String ] The atomic path.
        #
        # @since 3.0.0
        def path
          @path ||= _unscoped.first.atomic_path
        end

        # Set the atomic path.
        #
        # @api private
        #
        # @example Set the atomic path.
        #   batchable.path = "addresses"
        #
        # @param [ String ] value The path.
        #
        # @return [ String ] The path.
        #
        # @since 3.0.0
        def path=(value)
          @path = value
        end

        # Get the selector for executing atomic operations on the collection.
        #
        # @api private
        #
        # @example Get the selector.
        #   batchable.selector
        #
        # @return [ Hash ] The atomic selector.
        #
        # @since 3.0.0
        def selector
          @selector ||= _base.atomic_selector
        end

        # Pre processes the batch insert for the provided documents.
        #
        # @api private
        #
        # @example Pre process the documents.
        #   batchable.pre_process_batch_insert(docs)
        #
        # @param [ Array<Document> ] docs The documents.
        #
        # @return [ Array<Hash> ] The documents as an array of hashes.
        #
        # @since 3.0.0
        def pre_process_batch_insert(docs)
          docs.map do |doc|
            next unless doc
            append(doc)
            if persistable? && !_assigning?
              self.path = doc.atomic_path unless path
              if doc.valid?(:create)
                doc.run_before_callbacks(:save, :create)
              else
                self.inserts_valid = false
              end
            end
            doc.send(:as_attributes)
          end
        end

        # Pre process the batch removal.
        #
        # @api private
        #
        # @example Pre process the documents.
        #   batchable.pre_process_batch_remove(docs, :delete)
        #
        # @param [ Array<Document> ] docs The documents.
        # @param [ Symbol ] method Delete or destroy.
        #
        # @return [ Array<Hash> ] The documents as hashes.
        #
        # @since 3.0.0
        def pre_process_batch_remove(docs, method)
          docs.map do |doc|
            self.path = doc.atomic_path unless path
            execute_callback :before_remove, doc
            unless _assigning?
              doc.apply_delete_dependencies!
              doc.run_before_callbacks(:destroy) if method == :destroy
            end
            _target.delete_one(doc)
            _unscoped.delete_one(doc)
            unbind_one(doc)
            execute_callback :after_remove, doc
            doc.send(:as_attributes)
          end
        end

        # Post process the documents after batch insert.
        #
        # @api private
        #
        # @example Post process the documents.
        #   batchable.post_process_batch_insert(docs)
        #
        # @param [ Array<Documents> ] docs The inserted docs.
        #
        # @return [ Enumerable ] The document enum.
        #
        # @since 3.0.0
        def post_process_batch_insert(docs)
          docs.each do |doc|
            doc.new_record = false
            doc.run_after_callbacks(:create, :save)
            doc.post_persist
          end
        end

        # Post process the batch removal.
        #
        # @api private
        #
        # @example Post process the documents.
        #   batchable.post_process_batch_remove(docs, :delete)
        #
        # @param [ Array<Document> ] docs The documents.
        # @param [ Symbol ] method Delete or destroy.
        #
        # @return [ Array<Document> ] The documents.
        #
        # @since 3.0.0
        def post_process_batch_remove(docs, method)
          docs.each do |doc|
            doc.run_after_callbacks(:destroy) if method == :destroy
            doc.freeze
            doc.destroyed = true
          end
        end
      end
    end
  end
end
