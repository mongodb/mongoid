# encoding: utf-8
module Mongoid
  module Relations
    module Embedded

      # Contains behaviour for executing operations in batch on embedded
      # documents.
      module Batchable

        # Insert new documents as a batch push ($pushAll). This ensures that
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
          execute_batch_insert(docs, "$pushAll")
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
          if !docs.empty? && !_assigning?
            collection.find(selector).update("$pullAll" => { path => removals })
            post_process_batch_remove(docs, method)
          end
          Threaded.clear_options!
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
              base.atomic_unsets.push(first.atomic_path)
            end
            clear
          else
            base.delayed_atomic_sets.clear
            docs = normalize_docs(docs).compact
            target.clear and _unscoped.clear
            inserts = execute_batch_insert(docs, "$set")
            base.delayed_atomic_sets[path] = inserts if _assigning?
          end
        end

        private

        # @attribute [rw] inserts_valid If all inserts are valid.
        attr_accessor :inserts_valid

        # @attribute [w] path The atomic path
        attr_writer :path

        # Perform a batch persist of the provided documents with the supplied
        # operation.
        #
        # @api private
        #
        # @example Perform a batch operation.
        #   batchable.execute_batch(docs, "$set")
        #
        # @param [ Array<Document> ] docs The docs to persist.
        # @param [ String ] operation The atomic operation.
        #
        # @return [ Array<Hash> ] The inserts.
        #
        # @since 3.0.0
        def execute_batch_insert(docs, operation)
          self.inserts_valid = true
          inserts = pre_process_batch_insert(docs)
          if insertable?
            collection.find(selector).update(operation => { path => inserts })
            post_process_batch_insert(docs)
          end
          inserts
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
            Many.builder(base, metadata, docs).build
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
          @path ||= first.atomic_path
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
          @selector ||= base.atomic_selector
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
            doc.as_document
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
            if !_assigning? && !metadata.versioned?
              doc.cascade!
              doc.run_before_callbacks(:destroy) if method == :destroy
            end
            target.delete_one(doc)
            _unscoped.delete_one(doc)
            unbind_one(doc)
            doc.as_document
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
            IdentityMap.remove(doc)
          end
        end
      end
    end
  end
end
