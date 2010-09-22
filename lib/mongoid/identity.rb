# encoding: utf-8
module Mongoid #:nodoc:
  class Identity #:nodoc:
    # Create the identity for the +Document+.
    #
    # The id will be set in either in the form of a Mongo
    # +ObjectID+ or a composite key set up by defining a key on the document.
    #
    # The _type will be set to the document's class name.
    def create
      identify!; type!
    end

    # Create the new identity generator - this will be expanded in the future
    # to support pk generators.
    #
    # Options:
    #
    # document: The document to generate an id for.
    def initialize(document)
      @document = document
    end

    protected
    # Return the proper id for the document.
    def generate_id
      id = BSON::ObjectId.new
      @document.using_object_ids? ? id : id.to_s
    end

    # Set the id for the document.
    def identify!
      @document.id = compose.join(" ").identify if @document.primary_key
      @document.id = generate_id if @document.id.blank?
    end

    # Set the _type field on the @document.
    def type!
      @document._type = @document.class.name if @document.hereditary? || @document.class.descendants.any?
    end

    # Generates the composite key for a @document.ment.
    def compose
      @document.primary_key.collect { |key| @document.attributes[key] }.reject { |val| val.nil? }
    end
  end
end
