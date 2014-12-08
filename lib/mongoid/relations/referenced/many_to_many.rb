# encoding: utf-8
module Mongoid
  module Relations
    module Referenced

      # This class defines the behaviour for all relations that are a
      # many-to-many between documents in different collections.
      class ManyToMany < Many

        # Appends a document or array of documents to the relation. Will set
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
        # @param [ Document, Array<Document> ] *args Any number of documents.
        #
        # @return [ Array<Document> ] The loaded docs.
        #
        # @since 2.0.0.beta.1
        def <<(*args)
          docs = args.flatten
          return concat(docs) if docs.size > 1
          if doc = docs.first
            append(doc)
            base.add_to_set(foreign_key => doc.send(__metadata.primary_key))
            if child_persistable?(doc)
              doc.save
            end
          end
          unsynced(base, foreign_key) and self
        end
        alias :push :<<

        # Appends an array of documents to the relation. Performs a batch
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
          ids, docs, inserts = {}, [], []
          documents.each do |doc|
            next unless doc
            append(doc)
            if persistable? || _creating?
              ids[doc._id] = true
              save_or_delay(doc, docs, inserts)
            else
              existing = base.send(foreign_key)
              unless existing.include?(doc._id)
                existing.push(doc._id) and unsynced(base, foreign_key)
              end
            end
          end
          if persistable? || _creating?
            base.push(foreign_key => ids.keys)
          end
          persist_delayed(docs, inserts)
          self
        end

        # Build a new document from the attributes and append it to this
        # relation without saving.
        #
        # @example Build a new document on the relation.
        #   person.posts.build(:title => "A new post")
        #
        # @overload build(attributes = {}, type = nil)
        #   @param [ Hash ] attributes The attributes of the new document.
        #   @param [ Class ] type The optional subclass to build.
        #
        # @overload build(attributes = {}, type = nil)
        #   @param [ Hash ] attributes The attributes of the new document.
        #   @param [ Class ] type The optional subclass to build.
        #
        # @return [ Document ] The new document.
        #
        # @since 2.0.0.beta.1
        def build(attributes = {}, type = nil)
          doc = Factory.build(type || klass, attributes)
          base.send(foreign_key).push(doc._id)
          append(doc)
          doc.apply_post_processed_defaults
          unsynced(doc, inverse_foreign_key)
          yield(doc) if block_given?
          doc
        end
        alias :new :build

        # Delete the document from the relation. This will set the foreign key
        # on the document to nil. If the dependent options on the relation are
        # :delete or :destroy the appropriate removal will occur.
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
          doc = super
          if doc && persistable?
            base.pull(foreign_key => doc.send(__metadata.primary_key))
            target._unloaded = criteria
            unsynced(base, foreign_key)
          end
          doc
        end

        # Removes all associations between the base document and the target
        # documents by deleting the foreign keys and the references, orphaning
        # the target documents in the process.
        #
        # @example Nullify the relation.
        #   person.preferences.nullify
        #
        # @since 2.0.0.rc.1
        def nullify
          target.each do |doc|
            execute_callback :before_remove, doc
          end
          unless __metadata.forced_nil_inverse?
            criteria.pull(inverse_foreign_key => base._id)
          end
          if persistable?
            base.set(foreign_key => base.send(foreign_key).clear)
          end
          after_remove_error = nil
          many_to_many = target.clear do |doc|
            unbind_one(doc)
            unless __metadata.forced_nil_inverse?
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
        # in the relation. If the new target is nil, perform the necessary
        # deletion.
        #
        # @example Replace the relation.
        # person.preferences.substitute([ new_post ])
        #
        # @param [ Array<Document> ] replacement The replacement target.
        #
        # @return [ Many ] The relation.
        #
        # @since 2.0.0.rc.1
        def substitute(replacement)
          purge
          unless replacement.blank?
            push(replacement.compact.uniq)
          else
            reset_unloaded
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
        #
        # @since 2.4.0
        def unscoped
          klass.unscoped.any_in(_id: base.send(foreign_key))
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # @example Append the document to the relation.
        #   relation.append(document)
        #
        # @param [ Document ] document The document to append to the target.
        #
        # @since 2.0.0.rc.1
        def append(document)
          execute_callback :before_add, document
          target.push(document)
          characterize_one(document)
          bind_one(document)
          execute_callback :after_add, document
        end

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @return [ Binding ] The binding.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Referenced::ManyToMany.new(base, target, __metadata)
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
        # @return [ true, false ] If the document can be persisted.
        #
        # @since 3.0.20
        def child_persistable?(doc)
          (persistable? || _creating?) &&
            !(doc.persisted? && __metadata.forced_nil_inverse?)
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        def criteria
          ManyToMany.criteria(__metadata, base.send(foreign_key))
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
        #
        # @since 3.0.0
        def unsynced(doc, key)
          doc.synced[key] = false
          true
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::ManyToMany.builder(meta, object)
          #
          # @param [ Document ] base The base document.
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(base, meta, object)
            Builders::Referenced::ManyToMany.new(base, meta, object)
          end

          # Create the standard criteria for this relation given the supplied
          # metadata and object.
          #
          # @example Get the criteria.
          #   Proxy.criteria(meta, object)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Object ] object The object for the criteria.
          # @param [ Class ] type The criteria class.
          #
          # @return [ Criteria ] The criteria.
          #
          # @since 2.1.0
          def criteria(metadata, object, type = nil)
            apply_ordering(
              metadata.klass.all_of(
                metadata.primary_key => { "$in" => object || [] }
              ), metadata
            )
          end

          def eager_load_klass
            Relations::Eager::HasAndBelongsToMany
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::ManyToMany.embedded?
          #
          # @return [ false ] Always false.
          #
          # @since 2.0.0.rc.1
          def embedded?
            false
          end

          # Get the foreign key for the provided name.
          #
          # @example Get the foreign key.
          #   Referenced::ManyToMany.foreign_key(:person)
          #
          # @param [ Symbol ] name The name.
          #
          # @return [ String ] The foreign key.
          #
          # @since 3.0.0
          def foreign_key(name)
            "#{name.to_s.singularize}#{foreign_key_suffix}"
          end

          # Get the default value for the foreign key.
          #
          # @example Get the default.
          #   Referenced::ManyToMany.foreign_key_default
          #
          # @return [ Array ] Always an empty array.
          #
          # @since 2.0.0.rc.1
          def foreign_key_default
            []
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # @example Get the suffix for the foreign key.
          #   Referenced::ManyToMany.foreign_key_suffix
          #
          # @return [ String ] "_ids"
          #
          # @since 2.0.0.rc.1
          def foreign_key_suffix
            "_ids"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the macro.
          #   Referenced::ManyToMany.macro
          #
          # @return [ Symbol ] :has_and_belongs_to_many
          def macro
            :has_and_belongs_to_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::ManyToMany.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The options for the builder.
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
          # @return [ NestedBuilder ] A newly instantiated nested builder object.
          #
          # @since 2.0.0.rc.1
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::Many.new(metadata, attributes, options)
          end

          # Get the path calculator for the supplied document.
          #
          # @example Get the path calculator.
          #   Proxy.path(document)
          #
          # @param [ Document ] document The document to calculate on.
          #
          # @return [ Root ] The root atomic path calculator.
          #
          # @since 2.1.0
          def path(document)
            Mongoid::Atomic::Paths::Root.new(document)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Referenced::Many.stores_foreign_key?
          #
          # @return [ true ] Always true.
          #
          # @since 2.0.0.rc.1
          def stores_foreign_key?
            true
          end

          # Get the valid options allowed with this relation.
          #
          # @example Get the valid options.
          #   Relation.valid_options
          #
          # @return [ Array<Symbol> ] The valid options.
          #
          # @since 2.1.0
          def valid_options
            [
              :after_add,
              :after_remove,
              :autosave,
              :before_add,
              :before_remove,
              :dependent,
              :foreign_key,
              :index,
              :order,
              :primary_key
            ]
          end

          # Get the default validation setting for the relation. Determines if
          # by default a validates associated will occur.
          #
          # @example Get the validation default.
          #   Proxy.validation_default
          #
          # @return [ true, false ] The validation default.
          #
          # @since 2.1.9
          def validation_default
            true
          end
        end
      end
    end
  end
end
