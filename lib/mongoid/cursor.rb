# encoding: utf-8
module Mongoid #:nodoc
  class Cursor
    include Mongoid::Collections::Retry
    include Enumerable
    # Operations on the Mongo::Cursor object that will not get overriden by the
    # Mongoid::Cursor are defined here.
    OPERATIONS = [
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
      define_method(name) do |*args|
        retry_on_connection_failure do
          @cursor.send(name, *args)
        end
      end
    end

    # Iterate over each document in the cursor and yield to it.
    #
    # Example:
    #
    # <tt>cursor.each { |doc| p doc.title }</tt>
    def each
      @cursor.each do |document|
        yield Mongoid::Factory.from_db(@klass, document)
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
    # <tt>Mongoid::Cursor.new(Person, cursor)</tt>
    def initialize(klass, collection, cursor)
      @klass, @collection, @cursor = klass, collection, cursor
    end

    # Return the next document in the cursor. Will instantiate a new Mongoid
    # document with the attributes.
    #
    # Example:
    #
    # <tt>cursor.next_document</tt>
    def next_document
      Mongoid::Factory.from_db(@klass, @cursor.next_document)
    end

    # Returns an array of all the documents in the cursor.
    #
    # Example:
    #
    # <tt>cursor.to_a</tt>
    def to_a
      @cursor.to_a.collect { |attrs| Mongoid::Factory.from_db(@klass, attrs) }
    end
  end
end
