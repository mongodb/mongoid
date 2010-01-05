# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when querying the database for a document by a specific id which
    # does not exist.
    class DocumentNotFound < RuntimeError
      def initialize(klass, identifier)
        @klass, @identifier = klass, identifier
      end
      def message
        "Document not found for class #{@klass} and id #{@identifier}"
      end
    end

    # Raised when invalid options are passed into a constructor or method.
    class InvalidOptions < RuntimeError; end

    # Raised when the database connection has not been set up.
    class InvalidDatabase < RuntimeError; end

    # Raised when a persisence method ending in ! fails validation.
    class Validations < RuntimeError
      def initialize(errors)
        @errors = errors
      end
      def message
        "Validation failed: #{@errors.full_messages}"
      end
    end

    # This error is raised when trying to access a Mongo::Collection from an
    # embedded document.
    class InvalidCollection < RuntimeError
      def initialize(klass)
        @klass = klass
      end
      def message
        "Access to the collection for #{@klass.name} is not allowed " +
          "since it is an embedded document, please access a collection from " +
          "the root document"
      end
    end

  end
end
