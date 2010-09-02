# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class Many < Proxy

        def bind
        end

        # Appends a document or array of documents to the relation. Will set
        # the parent and update the index in the process.
        #
        # Example:
        #
        # <tt>relation << document</tt>
        #
        # Options:
        #
        # docs: Any number of documents.
        def <<(*docs)
          docs.flatten.each do |doc|
            append(doc)
          end
        end
        alias :concat :<<
        alias :push :<<

        # Builds a new document in the relation and appends it to the target.
        # Takes an optional type if you want to specify a subclass.
        #
        # Example:
        #
        # <tt>relation.build(:name => "Bozo")</tt>
        #
        # Options:
        #
        # attributes: The attributes to build the document with.
        # type: Optional class to build the document with.
        #
        # Returns:
        #
        # The new document.
        def build(attributes = {}, type = nil)
          instantiated(type).tap do |doc|
            append(doc)
            doc.write_attributes(attributes)
          end
        end

        # Returns a count of the number of documents in the association that have
        # actually been persisted to the database.
        #
        # Use #size if you want the total number of documents.
        #
        # Returns:
        #
        # The total number of persisted embedded docs, as flagged by the
        # #persisted? method.
        def count
          target.select(&:persisted?).size
        end

        # Create a new document in the relation. This is essentially the same
        # as doing a #build then #save on the new document.
        #
        # Example:
        #
        # <tt>relation.create(:name => "Bozo")</tt>
        #
        # Options:
        #
        # attributes: The attributes to build the document with.
        # type: Optional class to create the document with.
        #
        # Returns:
        #
        # The newly created document.
        def create(attributes = {}, type = nil)
          build(attributes, type).tap(&:save)
        end

        # Create a new document in the relation. This is essentially the same
        # as doing a #build then #save on the new document. If validation
        # failed on the document an error will get raised.
        #
        # Example:
        #
        # <tt>relation.create(:name => "Bozo")</tt>
        #
        # Options:
        #
        # attributes: The attributes to build the document with.
        # type: Optional class to create the document with.
        #
        # Returns:
        #
        # The newly created document or raises a validation error.
        def create!(attributes = {}, type = nil)
          build(attributes, type).tap(&:save!)
        end

        # Delete all the documents in the association without running callbacks.
        #
        # Example:
        #
        # <tt>addresses.delete_all</tt>
        #
        # Options:
        #
        # conditions: Optional conditions hash to limit what gets deleted.
        #
        # Returns:
        #
        # The number of documents deleted.
        def delete_all(conditions = {})
          remove_all(conditions, false)
        end

        # Destroy all the documents in the association whilst running callbacks.
        #
        # Example:
        #
        # <tt>addresses.destroy_all</tt>
        #
        # Options:
        #
        # conditions: Optional conditions hash to limit what gets destroyed.
        #
        # Returns:
        #
        # The number of documents destroyed.
        def destroy_all(conditions = {})
          remove_all(conditions, true)
        end

        # Finds a document in this association.
        #
        # Options:
        #
        # parameter: If :all is passed, returns all the documents else
        #            if an id is passed, will return the document for that id.
        #
        # Returns:
        #
        # A single matching +Document+.
        def find(parameter)
          return target if parameter == :all
          criteria.id(parameter).first
        end

        # Instantiate a new embeds_many relation.
        #
        # Options:
        #
        # base: The document this relation hangs off of.
        # target: The target [child document array] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            target.each_with_index do |doc, index|
              doc.parentize(base)
              doc._index = index
            end
          end
        end

        # Paginate the association. Will create a new criteria, set the documents
        # on it and execute in an enumerable context.
        #
        # Options:
        #
        # options: A +Hash+ of pagination options.
        #
        # Returns:
        #
        # A +WillPaginate::Collection+.
        def paginate(options)
          criteria = Mongoid::Criteria.translate(metadata.klass, options)
          criteria.documents = target
          criteria.paginate(options)
        end

        # Substitutes the supplied target documents for the existing documents
        # in the relation.
        #
        # Example:
        #
        # <tt>addresses.substitute([ address ])</tt>
        #
        # Options:
        #
        # target: An array of documents to replace the existing docs.
        #
        # Returns:
        #
        # The relation.
        def substitute(documents)
          target.clear
          documents.to_a.each { |doc| append(doc) } unless documents.nil?
          self
        end

        def unbind
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
          metadatafy(document)
          document.parentize(base)
          target << document
          document._index = target.size - 1
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # Example:
        #
        # <tt>relation.criteria</tt>
        #
        # Returns:
        #
        # A +Criteria+ object for this relation.
        def criteria
          metadata.klass.criteria.tap do |criterion|
            criterion.documents = target
          end
        end

        # If the target array does not respond to the supplied method then try to
        # find a named scope or criteria on the class and send the call there.
        #
        # If the method exists on the array, use the default proxy behavior.
        #
        # Options:
        #
        # name: The name of the method.
        # args: The method args
        # block: Optional block to pass.
        #
        # Returns:
        #
        # A Criteria or return value from the target.
        def method_missing(name, *args, &block)
          return super if target.respond_to?(name)
          klass = metadata.klass
          klass.send(:with_scope, criteria) do
            klass.send(name, *args)
          end
        end

        # Remove all documents from the relation, either with a delete or a
        # destroy depending on what this was called through.
        #
        # Options:
        #
        # conditions: Hash of conditions to filter by.
        # destroy: If true destroy, else delete.
        #
        # Returns:
        #
        # The number of documents removed.
        def remove_all(conditions = {}, destroy = false)
          criteria = metadata.klass.find(conditions || {})
          criteria.documents = target
          criteria.size.tap do
            criteria.each do |doc|
              target.delete(doc)
              destroy ? doc.destroy : doc.delete
            end
          end
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>Embedded::Many.builder(meta, object, person)</tt>
          #
          # Options:
          #
          # meta: The metadata of the relation.
          # object: A document or attributes array to build with.
          #
          # Returns:
          #
          # A newly instantiated builder object.
          def builder(meta, object)
            Builders::Embedded::Many.new(meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # Example:
          #
          # <tt>Embedded::Many.embedded?</tt>
          #
          # Returns:
          #
          # true
          def embedded?
            true
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # Example:
          #
          # <tt>Mongoid::Relations::Embedded::Many.macro</tt>
          #
          # Returns:
          #
          # <tt>:embeds_many</tt>
          def macro
            :embeds_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # Example:
          #
          # <tt>NestedAttributes::Many.builder(attributes, options)</tt>
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
            Builders::NestedAttributes::Many.new(metadata, attributes, options)
          end
        end
      end
    end
  end
end
