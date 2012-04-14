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
          self.inserts_valid = true
          inserts = pre_process_batch_insert(docs)
          if persistable? && inserts_valid
            collection.find(selector).update("$pushAll" => { path => inserts })
            post_process_batch_insert(docs)
          end
        end

        private

        # @attribute [rw] path The atomic path
        # @attribute [rw] inserts_valid If all inserts are valid.
        attr_accessor :path, :inserts_valid

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
            if persistable?
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
      end
    end
  end
end
