# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:

      # This class defines the behaviour for all relations that are a
      # many-to-many between documents in different collections.
      class ManyToMany < Referenced::Many

        # Appends a document or array of documents to the relation. Will set
        # the parent and update the index in the process.
        #
        # @example Append a document.
        #   person.addresses << address
        #
        # @example Push a document.
        #   person.addresses.push(address)
        #
        # @example Concat with other documents.
        #   person.addresses.concat([ address_one, address_two ])
        #
        # @param [ Document, Array<Document> ] *args Any number of documents.
        def <<(*args)
          options = default_options(args)
          args.flatten.each do |doc|
            return doc unless doc
            append(doc, options)
            base.add_to_set(metadata.foreign_key, doc.id)
            doc.save if base.persisted? && !options[:binding]
          end
        end
        alias :concat :<<
        alias :push :<<

        # Builds a new document in the relation and appends it to the target.
        # Takes an optional type if you want to specify a subclass.
        #
        # @example Build a new document on the relation.
        #   person.people.build(:name => "Bozo")
        #
        # @param [ Hash ] attributes The attributes to build the document with.
        # @param [ Class ] type Optional class to build the document with.
        #
        # @return [ Document ] The new document.
        def build(attributes = {}, type = nil, &block)
          super.tap do |doc|
            base.send(metadata.foreign_key).push(doc.id)
          end
        end
        alias :new :build

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted.
        #
        # @example Create and save the new document.
        #   person.preferences.create(:text => "Testing")
        #
        # @param [ Hash ] attributes The attributes to create with.
        # @param [ Class ] type The optional type of document to create.
        #
        # @return [ Document ] The newly created document.
        def create(attributes = nil, type = nil, &block)
          build(attributes, type, &block).tap do |doc|
            base.add_to_set(metadata.foreign_key, doc.id)
            doc.save if base.persisted?
          end
        end

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted and will raise an
        # error if validation fails.
        #
        # @example Create and save the new document.
        #   person.preferences.create!(:text => "Testing")
        #
        # @param [ Hash ] attributes The attributes to create with.
        # @param [ Class ] type The optional type of document to create.
        #
        # @raise [ Errors::Validations ] If validation failed.
        #
        # @return [ Document ] The newly created document.
        def create!(attributes = nil, type = nil, &block)
          build(attributes, type, &block).tap do |doc|
            base.add_to_set(metadata.foreign_key, doc.id)
            doc.save! if base.persisted?
          end
        end

        # Delete a single document from the relation.
        #
        # @example Delete a document.
        #   person.preferences.delete(preference)
        #
        # @param [ Document ] document The document to delete.
        #
        # @since 2.0.0.rc.1
        def delete(document, options = {})
          target.delete(document).tap do |doc|
            binding.unbind_one(doc, default_options.merge!(options)) if doc
          end
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # @example Delete all documents in the relation.
        #   person.preferences.delete_all
        #
        # @example Conditonally delete all documents in the relation.
        #   person.preferences.delete_all(:conditions => { :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to delete with.
        #
        # @return [ Integer ] The number of documents deleted.
        def delete_all(conditions = nil)
          remove_all(conditions, :delete_all)
        end

        # Destroys all related documents from the database given the supplied
        # conditions.
        #
        # @example Destroy all documents in the relation.
        #   person.preferences.destroy_all
        #
        # @example Conditonally destroy all documents in the relation.
        #   person.preferences.destroy_all(:conditions => { :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to destroy with.
        #
        # @return [ Integer ] The number of documents destroyd.
        def destroy_all(conditions = nil)
          remove_all(conditions, :destroy_all)
        end

        # Instantiate a new references_many relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # @example Create the new relation.
        #   Referenced::ManyToMany.new(base, target, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Array<Document> ] target The target of the relation.
        # @param [ Metadata ] metadata The relation's metadata.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            unless base.frozen?
              base.send(metadata.foreign_key_setter, target.map(&:id))
            end
          end
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
          load! and target.each do |doc|
            base.send(metadata.foreign_key).delete(doc.id)
            dereference(doc)
          end
          target.clear
        end
        alias :nullify_all :nullify

        # Substitutes the supplied target documents for the existing documents
        # in the relation. If the new target is nil, perform the necessary
        # deletion.
        #
        # @example Replace the relation.
        #   person.posts.substitute(new_name)
        #
        # @param [ Array<Document> ] target The replacement target.
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :binding Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @return [ Many ] The relation.
        #
        # @since 2.0.0.rc.1
        def substitute(new_target, options = {})
          tap do |relation|
            if new_target
              binding.unbind(options)
              relation.target = new_target.to_a
              base.send(metadata.foreign_key_setter, new_target.map(&:id))
              bind(options)
            else
              relation.target = unbind(options)
            end
          end
        end

        # Unbinds the base object to the inverse of the relation. This occurs
        # when setting a side of the relation to nil.
        #
        # Will delete the object if necessary.
        #
        # @example Unbind the target.
        #   person.posts.unbind
        #
        # @param [ Hash ] options The options to bind with.
        #
        # @option options [ true, false ] :binding Are we in build mode?
        # @option options [ true, false ] :continue Continue binding the
        #   inverse?
        #
        # @since 2.0.0.rc.1
        def unbind(options = {})
          target.each(&:delete) if base.persisted?
          binding.unbind(options)
          []
        end

        private

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Array<Document> ] new_target The new documents to bind with.
        #
        # @return [ Binding ] The binding.
        #
        # @since 2.0.0.rc.1
        def binding(new_target = nil)
          Bindings::Referenced::ManyToMany.new(base, new_target || target, metadata)
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        def criteria
          if metadata.inverse
            metadata.klass.any_in(metadata.inverse_foreign_key => [ base.id ])
          else
            metadata.klass.where(:_id => { "$in" => base.send(metadata.foreign_key) })
          end
        end

        # Dereferences the supplied document from the base of the relation.
        #
        # @example Dereference the document.
        #   person.preferences.dereference(preference)
        #
        # @param [ Document ] document The document to dereference.
        def dereference(document)
          document.send(metadata.inverse_foreign_key).delete(base.id)
          document.send(metadata.inverse(document)).target.delete(base)
          document.save
        end

        # Remove all documents from the relation, either with a delete or a
        # destroy depending on what this was called through.
        #
        # @example Destroy documents from the relation.
        #   relation.remove_all(:conditions => { :num => 1 }, true)
        #
        # @param [ Hash ] conditions Conditions to filter by.
        # @param [ true, false ] destroy If true then destroy, else delete.
        #
        # @return [ Integer ] The number of documents removed.
        def remove_all(conditions = {}, method = :destroy)
          cond = conditions || {}
          target.delete_if do |doc|
            doc.matches?(cond[:conditions] || {})
          end
          ids = criteria.merge(cond).only(:_id).map(&:_id)
          criteria.merge(cond).send(method).tap do
            base.pull_all(metadata.foreign_key, ids)
          end
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::ManyToMany.builder(meta, object)
          #
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(meta, object)
            Builders::Referenced::ManyToMany.new(meta, object)
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
          # @return [ Symbol ] :references_and_referenced_in_many
          def macro
            :references_and_referenced_in_many
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
        end
      end
    end
  end
end
