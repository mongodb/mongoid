# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:
      class ManyToMany < Relations::Many

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # Example:
        #
        # <tt>person.preferences.bind</tt>
        def bind(building = nil)
          binding.bind_all
          target.map(&:save) if base.persisted? && !building?
        end

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # Example:
        #
        # <tt>relation.clear</tt>
        #
        # Returns:
        #
        # The empty relation.
        def clear
          tap { |relation| relation.unbind }
        end

        def delete(document)
          target.delete(document)
          binding.unbind_one(document)
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # Example:
        #
        # <tt>person.posts.delete_all(:title => "Testing")</tt>
        #
        # Options:
        #
        # conditions: A hash of conditions to limit the delete by.
        #
        # Returns:
        #
        # The number of documents deleted.
        def delete_all(conditions = nil)
          selector = (conditions || {})[:conditions] || {}
          target.delete_if { |doc| doc.matches?(selector) }
          scoping = { :_id => { "$in" => base.send(metadata.foreign_key) } }
          metadata.klass.delete_all(:conditions => selector.merge(scoping))
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # Example:
        #
        # <tt>person.posts.destroy_all(:title => "Testing")</tt>
        #
        # Options:
        #
        # conditions: A hash of conditions to limit the delete by.
        #
        # Returns:
        #
        # The number of documents deleted.
        def destroy_all(conditions = nil)
          selector = (conditions || {})[:conditions] || {}
          target.delete_if { |doc| doc.matches?(selector) }
          scoping = { :_id => { "$in" => base.send(metadata.foreign_key) } }
          metadata.klass.destroy_all(:conditions => selector.merge(scoping))
        end

        # Find the matchind document on the association, either based on id or
        # conditions.
        #
        # Example:
        #
        # <tt>person.find(ObjectID("4c52c439931a90ab29000005"))</tt>
        # <tt>person.find(:all, :conditions => { :title => "Sir" })</tt>
        # <tt>person.find(:first, :conditions => { :title => "Sir" })</tt>
        # <tt>person.find(:last, :conditions => { :title => "Sir" })</tt>
        #
        # Options:
        #
        # arg: Either an id or a type of search.
        # options: a Hash of selector arguments.
        #
        # Returns:
        #
        # The matching document or documents.
        def find(arg, options = {})
          klass = metadata.klass
          return klass.criteria.id_criteria(arg) unless arg.is_a?(Symbol)
          selector = (options[:conditions] || {}).merge(
            "_id" => { "$in" => base.send(metadata.foreign_key) }
          )
          klass.find(arg, :conditions => selector)
        end

        # Instantiate a new references_many relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # Example:
        #
        # <tt>Referenced::ManyToMany.new(base, target, metadata)</tt>
        #
        # Options:
        #
        # base: The document this relation hangs off of.
        # target: The target [child documents] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata)
        end

        # Removes all associations between the base document and the target
        # documents by deleting the foreign keys and the references, orphaning
        # the target documents in the process.
        #
        # @example Nullify the relation.
        #   person.preferences.nullify
        def nullify
          loaded and target.each do |doc|
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
        # Example:
        #
        # <tt>posts.substitute(new_name)</tt>
        #
        # Options:
        #
        # target: An array of documents to replace the target.
        #
        # Returns:
        #
        # The relation or nil.
        def substitute(target, building = nil)
          tap { target ? (@target = target.to_a; bind) : (@target = unbind) }
        end

        # Unbinds the base object to the inverse of the relation. This occurs
        # when setting a side of the relation to nil.
        #
        # Will delete the object if necessary.
        #
        # Example:
        #
        # <tt>person.posts.unbind</tt>
        def unbind
          target.each(&:delete) if base.persisted?
          binding.unbind_all
          []
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # Example:
        #
        # <tt>relation.append(document)</tt>
        #
        # Options:
        #
        # document: The document to append to the target.
        def append(document)
          target.push(document)
          metadatafy(document)
          binding.bind_one(document)
        end

        # Instantiate the binding associated with this relation.
        #
        # Example:
        #
        # <tt>binding([ address ])</tt>
        #
        # Options:
        #
        # new_target: The new documents to bind with.
        #
        # Returns:
        #
        # A binding object.
        def binding(new_target = nil)
          Bindings::Referenced::ManyToMany.new(base, new_target || target, metadata)
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

        # Will load the target into an array if the target had not already been
        # loaded.
        #
        # Example:
        #
        # <tt>person.addresses.loaded</tt>
        #
        # Returns:
        #
        # The relation itself.
        def loaded
          tap do |relation|
            relation.target = target.entries if target.is_a?(Mongoid::Criteria)
          end
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.builder(meta, object)</tt>
          #
          # Options:
          #
          # meta: The metadata of the relation.
          # object: A document or attributes to build with.
          #
          # Returns:
          #
          # A newly instantiated builder object.
          def builder(meta, object)
            Builders::Referenced::ManyToMany.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.embedded?</tt>
          #
          # Returns:
          #
          # true
          def embedded?
            false
          end

          def foreign_key_default
            []
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.foreign_key_suffix</tt>
          #
          # Returns:
          #
          # "_id"
          def foreign_key_suffix
            "_ids"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Referenced::ManyToMany.macro</tt>
          #
          # Returns:
          #
          # <tt>:references_and_referenced_in_many</tt>
          def macro
            :references_and_referenced_in_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Referenced::Nested::ManyToMany.builder(attributes, options)</tt>
          #
          # Options:
          #
          # attributes: The attributes to build with.
          # options: The options for the builder.
          #
          # Returns:
          #
          # A newly instantiated nested builder object.
          def nested_builder(metadata, attributes, options)
            Builders::Referenced::Nested::ManyToMany.new(metadata, attributes, options)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # Example:
          #
          # <tt>Referenced::ManyToMany.stores_foreign_key?</tt>
          #
          # Returns:
          #
          # true
          def stores_foreign_key?
            true
          end
        end
      end
    end
  end
end
