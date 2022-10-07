# frozen_string_literal: true

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
        def batch_clear(docs)
          pre_process_batch_remove(docs, :delete)
          unless docs.empty?
            collection.find(selector).update_one(
              positionally(selector, "$unset" => { path => true }),
              session: _session
            )
            unless Mongoid.broken_updates
              # This solves the case in which a user sets, clears and resets an
              # embedded document. Previously, since the embedded document was
              # already marked not a "new_record", it wouldn't be persisted to
              # the second time. This change fixes that and allows it to be persisted.
              docs.each { |doc| doc.new_record = true }
            end
            post_process_batch_remove(docs, :delete)
          end
          _unscoped.clear
        end

        # Batch remove the provided documents as a $pullAll or $pull.
        #
        # @example Batch remove the documents.
        #   batchable.batch_remove([ doc_one, doc_two ])
        #
        # @param [ Array<Document> ] docs The docs to remove.
        # @param [ Symbol ] method Delete or destroy.
        def batch_remove(docs, method = :delete)
          # If the _id is nil, we cannot use $pull and delete by searching for
          # the id. Therefore we have to use pullAll with the documents'
          # attributes.
          removals = pre_process_batch_remove(docs, method)
          pulls, pull_alls = removals.partition { |o| !o["_id"].nil? }

          if !_base.persisted?
            post_process_batch_remove(docs, method) unless docs.empty?
            return reindex
          end

          if !docs.empty?
            if !pulls.empty?
              collection.find(selector).update_one(
                positionally(selector, "$pull" => { path => { "_id" => { "$in" => pulls.pluck("_id") } } }),
                session: _session
              )
            end
            if !pull_alls.empty?
              collection.find(selector).update_one(
                positionally(selector, "$pullAll" => { path => pull_alls }),
                session: _session
              )
            end
            post_process_batch_remove(docs, method)
          else
            collection.find(selector).update_one(
              positionally(selector, "$set" => { path => [] }),
              session: _session
            )
          end
          reindex
        end

        # Batch replace the provided documents as a $set.
        #
        # @example Batch replace the documents.
        #   batchable.batch_replace([ doc_one, doc_two ])
        #
        # @param [ Array<Document> | Array<Hash> ] docs The docs to replace with.
        #
        # @return [ Array<Hash> ] The inserts.
        def batch_replace(docs)
          if docs.blank?
            if _assigning? && !empty?
              _base.delayed_atomic_sets.delete(path)
              clear_atomic_path_cache
              _base.add_atomic_unset(first)
              target_duplicate = _target.dup
              pre_process_batch_remove(target_duplicate, :delete)
              post_process_batch_remove(target_duplicate, :delete)
            else
              batch_remove(_target.dup)
            end
          elsif _target != docs
            _base.delayed_atomic_sets.delete(path) unless _assigning?
            docs = normalize_docs(docs).compact
            _target.clear and _unscoped.clear
            _base.delayed_atomic_unsets.delete(path)
            clear_atomic_path_cache
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
        # @return [ true | false ] If inserts can be performed.
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
        # @return [ true | false ] If inserts are currently valid.
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
        # @param [ true | false ] value The flag.
        #
        # @return [ true | false ] The flag.
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
        # @param [ Array<Document> | Array<Hash> ] docs The docs to normalize.
        #
        # @return [ Array<Document> ] The docs.
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
        def path
          @path ||= if _unscoped.empty?
            Mongoid::Atomic::Paths::Embedded::Many.position_without_document(_base, _association)
          else
            _unscoped.first.atomic_path
          end
        end

        # Clear the cache for path and atomic_paths. This method is used when
        # the path method is used, and the association has not been set on the
        # document yet, which can cause path and atomic_paths to be calculated
        # incorrectly later.
        #
        # @api private
        def clear_atomic_path_cache
          self.path = nil
          _base.instance_variable_set("@atomic_paths", nil)
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
        def pre_process_batch_remove(docs, method)
          docs.map do |doc|
            self.path = doc.atomic_path unless path
            execute_callback :before_remove, doc
            unless _assigning?
              doc.apply_destroy_dependencies!
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
