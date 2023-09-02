# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasAndBelongsToMany

        # This class defines the behavior for all associations that are a
        # many-to-many between documents in different collections.
        class Proxy < Referenced::HasMany::Proxy

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
          # @param [ Document... ] *args Any number of documents.
          #
          # @return [ Array<Document> ] The loaded docs.
          def <<(*args)
            docs = args.flatten
            return concat(docs) if docs.size > 1
            if doc = docs.first
              append(doc) do
                # We ignore the changes to the value for the foreign key in the
                # changed_attributes hash in this block of code for two reasons:
                #
                # 1) The add_to_set method deletes the value for the foreign
                #    key in the changed_attributes hash, but if we enter this
                #    method with a value for the foreign key in the
                #    changed_attributes hash, then we want it to exist outside
                #    this method as well. It's used later on in the Syncable
                #    module to set the inverse foreign keys.
                # 2) The reset_unloaded method accesses the value for the foreign
                #    key on _base, which causes it to get added to the
                #    changed_attributes hash. This happens because when reading
                #    a "resizable" attribute, it is automatically added to the
                #    changed_attributes hash. This is true only for the foreign
                #    key value for HABTM associations as the other associations
                #    use strings for their foreign key values. For consistency
                #    with the other associations, we ignore this addition to
                #    the changed_attributes hash.
                #    See MONGOID-4843 for a longer discussion about this.
                reset_foreign_key_changes do
                  _base.add_to_set(foreign_key => doc.public_send(_association.primary_key))

                  if child_persistable?(doc)
                    doc.save
                  end
                  reset_unloaded
                end
              end
            end
            unsynced(_base, foreign_key) and self
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
          def concat(documents)
            ids, docs, inserts = {}, [], []
            documents.each do |doc|
              next unless doc
              append(doc)
              if persistable? || _creating?
                ids[doc.public_send(_association.primary_key)] = true
                save_or_delay(doc, docs, inserts)
              else
                existing = _base.public_send(foreign_key)
                unless existing.include?(doc.public_send(_association.primary_key))
                  existing.push(doc.public_send(_association.primary_key)) and unsynced(_base, foreign_key)
                end
              end
            end
            if persistable? || _creating?
              _base.push(foreign_key => ids.keys)
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
          def build(attributes = {}, type = nil)
            doc = Factory.execute_build(type || klass, attributes, execute_callbacks: false)
            append(doc)
            doc.apply_post_processed_defaults
            _base.public_send(foreign_key).push(doc.public_send(_association.primary_key))
            unsynced(doc, inverse_foreign_key)
            yield(doc) if block_given?
            doc.run_pending_callbacks
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
          def delete(document)
            doc = super
            if doc && persistable?
              _base.pull(foreign_key => doc.public_send(_association.primary_key))
              _target._unloaded = criteria
              unsynced(_base, foreign_key)
            end
            doc
          end

          # Mongoid::Extensions::Array defines Array#delete_one, so we need
          # to make sure that method behaves reasonably on proxies, too.
          alias delete_one delete

          # Removes all associations between the base document and the target
          # documents by deleting the foreign keys and the references, orphaning
          # the target documents in the process.
          #
          # @example Nullify the association.
          #   person.preferences.nullify
          #
          # @param [ Array<Document> ] replacement The replacement documents.
          def nullify(replacement = [])
            _target.each do |doc|
              execute_callback :before_remove, doc
            end
            unless _association.forced_nil_inverse?
              if field = _association.options[:inverse_primary_key]
                ipk = _base.public_send(field)
              else
                ipk = _base._id
              end
              if replacement
                objects_to_clear = _base.public_send(foreign_key) - replacement.collect do |object|
                  object.public_send(_association.primary_key)
                end
                criteria(objects_to_clear).pull(inverse_foreign_key => ipk)
              else
                criteria.pull(inverse_foreign_key => ipk)
              end
            end
            if persistable?
              _base.set(foreign_key => _base.public_send(foreign_key).clear)
            end
            after_remove_error = nil
            many_to_many = _target.clear do |doc|
              unbind_one(doc)
              unless _association.forced_nil_inverse?
                doc.changed_attributes.delete(inverse_foreign_key)
              end
              begin
                execute_callback :after_remove, doc
              rescue => e
                after_remove_error = e
              end
            end
            raise after_remove_error if after_remove_error
            many_to_many
          end

          alias :nullify_all :nullify
          alias :clear :nullify
          alias :purge :nullify

          # Substitutes the supplied target documents for the existing documents
          # in the association. If the new target is nil, perform the necessary
          # deletion.
          #
          # @example Replace the association.
          # person.preferences.substitute([ new_post ])
          #
          # @param [ Array<Document> ] replacement The replacement target.
          #
          # @return [ Many ] The association.
          def substitute(replacement)
            purge(replacement)
            unless replacement.blank?
              push(replacement.compact.uniq)
            else
              reset_unloaded
              clear_foreign_key_changes
            end
            self
          end

          # Get a criteria for the documents without the default scoping
          # applied.
          #
          # @example Get the unscoped criteria.
          #   person.preferences.unscoped
          #
          # @return [ Criteria ] The unscoped criteria.
          def unscoped
            klass.unscoped.any_in(_id: _base.public_send(foreign_key))
          end

          private

          # Clears the foreign key from the changed_attributes hash.
          #
          # This is, in general, used to clear the foreign key from the
          # changed_attributes hash for consistency with the other referenced
          # associations.
          #
          # @api private
          def clear_foreign_key_changes
            _base.changed_attributes.delete(foreign_key)
          end

          # Reset the value in the changed_attributes hash for the foreign key
          # to its value before executing the given block.
          #
          # @api private
          def reset_foreign_key_changes
            if _base.changed_attributes.key?(foreign_key)
              fk = _base.changed_attributes[foreign_key].dup
              yield if block_given?
              _base.changed_attributes[foreign_key] = fk
            else
              yield if block_given?
              clear_foreign_key_changes
            end
          end

          # Appends the document to the target array, updating the index on the
          # document at the same time.
          #
          # @example Append the document to the association.
          #   relation.append(document)
          #
          # @param [ Document ] document The document to append to the target.
          def append(document)
            execute_callbacks_around(:add, document) do
              _target.push(document)
              characterize_one(document)
              bind_one(document)
              yield if block_given?
            end
          end

          # Instantiate the binding associated with this association.
          #
          # @example Get the binding.
          #   relation.binding([ address ])
          #
          # @return [ Binding ] The binding.
          def binding
            HasAndBelongsToMany::Binding.new(_base, _target, _association)
          end

          # Determine if the child document should be persisted.
          #
          # @api private
          #
          # @example Is the child persistable?
          #   relation.child_persistable?(doc)
          #
          # @param [ Document ] doc The document.
          #
          # @return [ true | false ] If the document can be persisted.
          def child_persistable?(doc)
            (persistable? || _creating?) &&
                !(doc.persisted? && _association.forced_nil_inverse?)
          end

          # Returns the criteria object for the target class with its documents set
          # to target.
          #
          # @example Get a criteria for the association.
          #   relation.criteria
          #
          # @return [ Criteria ] A new criteria.
          def criteria(id_list = nil)
            _association.criteria(_base, id_list)
          end

          # Flag the base as unsynced with respect to the foreign key.
          #
          # @api private
          #
          # @example Flag as unsynced.
          #   relation.unsynced(doc, :preference_ids)
          #
          # @param [ Document ] doc The document to flag.
          # @param [ Symbol ] key The key to flag on the document.
          #
          # @return [ true ] true.
          def unsynced(doc, key)
            doc._synced[key] = false
            true
          end

          class << self

            # Get the Eager object for this type of association.
            #
            # @example Get the eager loader object
            #
            # @param [ Association ] association The association object.
            # @param [ Array<Document> ] docs The array of documents.
            def eager_loader(association, docs)
              Eager.new(association, docs)
            end

            # Returns true if the association is an embedded one. In this case
            # always false.
            #
            # @example Is this association embedded?
            #   Referenced::ManyToMany.embedded?
            #
            # @return [ false ] Always false.
            def embedded?
              false
            end
          end
        end
      end
    end
  end
end
