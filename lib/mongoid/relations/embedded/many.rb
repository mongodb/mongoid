# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Embedded
      class Many < OneToMany

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
            doc.parentize(@base, @metadata.name.to_s)
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
            doc.parentize(@base, @metadata.name.to_s)
            doc.write_attributes(attributes || {})
            append(doc)
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
          @target.select(&:persisted?).size
        end

        # Instantiate a new embeds_many relation.
        #
        # Options:
        #
        # base: The document this relation hangs off of.
        # target: The target [child document array] of the relation.
        # metadata: The relation's metadata
        def initialize(base, target, metadata)
          init(base, target, metadata)
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
        def substitute(target)
          target.nil? ? @target.clear : @target = target; self
        end
      end
    end
  end
end
