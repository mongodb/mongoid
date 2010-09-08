# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class Many < Proxy

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
            append(doc) unless target.include?(doc)
            doc.save if base.persisted?
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
        # <tt>person.addresses.bind</tt>
        def bind(building = nil)
          binding.bind_all
          target.each(&:save) if base.persisted? && !building
        end

        # Bind the inverse relation between a single document in this proxy
        # instead of the entire target.
        #
        # Used when appending to the target instead of setting the entire
        # thing.
        #
        # Example:
        #
        # <tt>person.addressses.bind_one(address)</tt>
        def bind_one(document)
          binding.bind_one(document)
        end

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
            doc.identify
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

        # Delete the supplied document from the target. This method is proxied
        # in order to reindex the array after the operation occurs.
        #
        # Example:
        #
        # <tt>addresses.delete(address)</tt>
        #
        # Options:
        #
        # document: The document to be deleted.
        #
        # Returns:
        #
        # The deleted document or nil if nothing deleted.
        def delete(document)
          target.delete(document).tap { reindex }
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
        def find(*args)
          type, criteria = Criteria.parse!(self, *args)
          case type
          when :first then return criteria.one
          when :last then return criteria.last
          else
            criteria.tap do |crit|
              crit.documents = target if crit.is_a?(Criteria)
            end
          end
        end

        # Find the first +Document+ given the conditions, or creates a new document
        # with the conditions that were supplied
        #
        # Example:
        #
        # <tt>person.addresses.find_or_create_by(:street => "Bond St")</tt>
        #
        # Options:
        #
        # attrs: A +Hash+ of attributes
        #
        # Returns:
        #
        # An existing document or newly created one.
        def find_or_create_by(attrs = {})
          find_or(:create, attrs)
        end

        # Find the first +Document+ given the conditions, or instantiates a new document
        # with the conditions that were supplied
        #
        # Example:
        #
        # <tt>person.addresses.find_or_initialize_by(:street => "Bond St")</tt>
        #
        # Options:
        #
        # attrs: A +Hash+ of attributes
        #
        # Returns:
        #
        # An existing document or new one.
        def find_or_initialize_by(attrs = {})
          find_or(:build, attrs)
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
        # new_target: An array of documents to replace the existing docs.
        #
        # Returns:
        #
        # The relation.
        def substitute(new_target, building = nil)
          old_target = target
          tap do |relation|
            relation.target = new_target || []
            !new_target.blank? ? bind(building) : unbind(old_target)
          end
        end

        def to_hash
          target.inject([]) do |attributes, doc|
            attributes.tap do |attr|
              attr << doc.to_hash
            end
          end
        end

        # Unbind the inverse relation from this set of documents. Used when the
        # entire proxy has been cleared, set to nil or empty, or replaced.
        #
        # Example:
        #
        # <tt>person.addresses.unbind(target)</tt>
        #
        # Options:
        #
        # old_target: The previous target of the relation to unbind with.
        def unbind(old_target)
          binding(old_target).unbind
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
          target << document
          metadatafy(document) and bind_one(document)
          document._index = target.size - 1
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
          Bindings::Embedded::Many.new(base, new_target || target, metadata)
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

        # Find the first object given the supplied attributes or create/initialize it.
        #
        # Example:
        #
        # <tt>person.addresses.find_or(:create, :street => "Bond")</tt>
        #
        # Options:
        #
        # method: The method name, create or new.
        # attrs: The attributes to build with
        #
        # Returns:
        #
        # A matching document or a new/created one.
        def find_or(method, attrs = {})
          find(:first, :conditions => attrs) || send(method, attrs)
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

        # Reindex all the target elements. This is useful when performing
        # operations on the proxied target directly and the indices need to
        # match that on the database side.
        #
        # Example:
        #
        # <tt>person.addresses.reindex</tt>
        def reindex
          target.each_with_index do |doc, index|
            doc._index = index
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

          def binding(base, target, metadata)
            Bindings::Embedded::Many.new(base, target, metadata)
          end

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
