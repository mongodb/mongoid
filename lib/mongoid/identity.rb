# encoding: utf-8
module Mongoid #:nodoc:
  class Identity #:nodoc:
    class << self
      # Create the identity for the +Document+.
      #
      # The id will be set in either in the form of a Mongo
      # +ObjectId+ or a composite key set up by defining a key on the document.
      #
      # The _type will be set to the document's class name.
      def create(doc)
        identify(doc); type(doc); doc
      end

      protected
      # Return the proper id for the document.
      def generate_id
        id = BSON::ObjectId.new
        Mongoid.use_object_ids ? id : id.to_s
      end

      # Set the id for the document.
      def identify(doc)
        doc.id = compose(doc).join(" ").identify if doc.primary_key
        doc.id = generate_id if doc.id.blank?
      end

      # Set the _type field on the document.
      def type(doc)
        doc._type = doc.class.name if doc.hereditary?
      end

      # Generates the composite key for a document.
      def compose(doc)
        doc.primary_key.collect { |key| doc.attributes[key] }.reject { |val| val.nil? }
      end
    end
  end
end
