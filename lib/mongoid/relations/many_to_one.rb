# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class ManyToOne < Proxy

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
          unless target.include?(doc)
            append(doc)
            doc.save if base.persisted?
          end
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

      # Determine if any documents in this relation exist in the database.
      #
      # Example:
      #
      # <tt>person.posts.exists?</tt>
      #
      # Returns:
      #
      # True is persisted documents exist, false if not.
      def exists?
        count > 0
      end

      # Find the first +Document+ given the conditions, or creates a new document
      # with the conditions that were supplied
      #
      # Example:
      #
      # <tt>person.posts.find_or_create_by(:title => "Testing")</tt>
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
      # <tt>person.posts.find_or_initialize_by(:title => "Test")</tt>
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

      private

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
    end
  end
end
