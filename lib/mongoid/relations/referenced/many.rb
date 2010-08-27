# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Referenced #:nodoc:
      class Many < Proxy

        # Append an object to the relation, which will bind the new object
        # and save it if the base is persisted.
        #
        # Example:
        #
        # <tt>person.posts << Post.new</tt>
        #
        # Options:
        #
        # document: The document to append.
        #
        # Returns:
        #
        # The relation.
        def <<(*documents)
          # TODO: Durran: Can move this into the binding.
          documents.flatten.each do |doc|
            doc.send(metadata.foreign_key_setter, base.id)
            doc.send(metadata.inverse_setter, base)
            doc.save if base.persisted? && !building?
            target << doc
          end
        end

        alias :concat :<<
        alias :push :<<

        # Binds the base object to the inverse of the relation. This is so we
        # are referenced to the actual objects themselves and dont hit the
        # database twice when setting the relations up.
        #
        # This is called after first creating the relation, or if a new object
        # is set on the relation.
        #
        # Example:
        #
        # <tt>person.posts.bind</tt>
        def bind
          Bindings::Referenced::Many.new(base, target, metadata).bind
          target.tap { |t| t.each(&:save) if base.persisted? && !building? }
        end

        # Builds a new document on the references many relation.
        #
        # Example:
        #
        # <tt>person.posts.build(:text => "Testing")</tt>
        #
        # Options:
        #
        # attributes:
        #
        # A hash of attributes to build the document with.
        #
        # Returns:
        #
        # The newly built document.
        def build(attributes = nil)
          metadata.klass.new(attributes).tap do |doc|
            building { self.<<(doc) }
          end
        end

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted.
        #
        # Example:
        #
        # <tt>person.posts.create(:text => "Testing")</tt>
        #
        # Options:
        #
        # attributes:
        #
        # A hash of attributes to create the document with.
        #
        # Returns:
        #
        # The newly created document.
        def create(attributes = nil)
          build(attributes).tap { |doc| doc.save if base.persisted? }
        end

        # Instantiate a new references_many relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # Example:
        #
        # <tt>Referenced::Many.new(base, target, metadata)</tt>
        #
        # Options:
        #
        # base: The document this relation hangs off of.
        # target: The target [child documents] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            @target = target.documents unless target
          end
        end

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
        def substitute(target)
          tap { target ? (@target = target.to_a and bind) : (@target = unbind) }
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
          Bindings::Referenced::Many.new(base, target, metadata).unbind
          target.each(&:delete) if base.persisted?
          []
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Referenced::Many.builder(meta, object)</tt>
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
            Builders::Referenced::Many.new(meta, object)
          end


          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # Example:
          #
          # <tt>Referenced::Many.embedded?</tt>
          #
          # Returns:
          #
          # true
          def embedded?
            false
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # Example:
          #
          # <tt>Referenced::Many.foreign_key_suffix</tt>
          #
          # Returns:
          #
          # "_id"
          def foreign_key_suffix
            "_id"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Referenced::Many.macro</tt>
          #
          # Returns:
          #
          # <tt>:references_many</tt>
          def macro
            :references_many
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # Example:
          #
          # <tt>Referenced::Many.stores_foreign_key?</tt>
          #
          # Returns:
          #
          # false
          def stores_foreign_key?
            false
          end
        end
      end
    end
  end
end
