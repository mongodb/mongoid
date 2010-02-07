# encoding: utf-8
module Mongoid #:nodoc
  class Cursor
    # Operations on the Mongo::Cursor object that will not get overriden by the
    # Mongoid::Cursor are defined here.
    OPERATIONS = [
      :admin,
      :close,
      :closed?,
      :count,
      :explain,
      :fields,
      :full_collection_name,
      :hint,
      :limit,
      :order,
      :query_options_hash,
      :query_opts,
      :selector,
      :skip,
      :snapshot,
      :sort,
      :timeout
    ]

    attr_reader :collection

    # The operations above will all delegate to the proxied Mongo::Cursor.
    #
    # Example:
    #
    # <tt>cursor.close</tt>
    OPERATIONS.each do |name|
      define_method(name) { |*args| @cursor.send(name, *args) }
    end

    # Iterate over each document in the cursor and yield to it.
    #
    # Example:
    #
    # <tt>cursor.each { |doc| p doc.title }</tt>
    def each
      @cursor.each do |document|
        yield init(document)
      end
    end

    # Create the new +Mongoid::Cursor+.
    #
    # Options:
    #
    # collection: The Mongoid::Collection instance.
    # cursor: The Mongo::Cursor to be proxied.
    #
    # Example:
    #
    # <tt>Mongoid::Cursor.new(collection, cursor)</tt>
    def initialize(collection, cursor)
      @collection, @cursor = collection, cursor
    end

    # Return the next document in the cursor. Will instantiate a new Mongoid
    # document with the attributes.
    #
    # Example:
    #
    # <tt>cursor.next_document</tt>
    def next_document
      init(@cursor.next_document)
    end

    # Returns an array of all the documents in the cursor.
    #
    # Example:
    #
    # <tt>cursor.to_a</tt>
    def to_a
      @cursor.to_a.collect { |attrs| init(attrs) }
    end

    protected
    # Create the new document from the _type in the attributes.
    def init(attrs)
      attrs["_type"].constantize.instantiate(attrs)
    end
  end
end
