# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when querying the database for a document by a specific id which
    # does not exist. If multiple ids were passed then it will display all of
    # those.
    #
    # Example:
    #
    # <tt>DocumentNotFound.new(Person, ["1", "2"])</tt>
    class DocumentNotFound < RuntimeError
      def initialize(klass, ids)
        @klass, @identifier = klass, ids.is_a?(Array) ? ids.join(", ") : ids
      end
      def message
        "Document not found for class #{@klass} and id(s) #{@identifier}"
      end
    end

    # Raised when invalid options are passed into a constructor or method.
    #
    # Example:
    #
    # <tt>InvalidOptions.new</tt>
    class InvalidOptions < RuntimeError; end

    # Raised when the database connection has not been set up properly, either
    # by attempting to set an object on the db that is not a +Mongo::DB+, or
    # not setting anything at all.
    #
    # Example:
    #
    # <tt>InvalidDatabase.new("Not a DB")</tt>
    class InvalidDatabase < RuntimeError
      def initialize(database)
        @database = database
      end
      def message
        "Database should be a Mongo::DB, not #{@database.class.name}"
      end
    end

    # Raised when the database version is not supported by Mongoid.
    #
    # Example:
    #
    # <tt>UnsupportedVersion.new(Mongo::ServerVersion.new("1.3.1"))</tt>
    class UnsupportedVersion < RuntimeError
      def initialize(version)
        @version = version
      end
      def message
        "MongoDB #{@version} not supported, please upgrade to #{Mongoid::MONGODB_VERSION}"
      end
    end

    # Raised when a persisence method ending in ! fails validation. The message
    # will contain the full error messages from the +Document+ in question.
    #
    # Example:
    #
    # <tt>Validations.new(person.errors)</tt>
    class Validations < RuntimeError
      def initialize(errors)
        @errors = errors
      end
      def message
        "Validation Failed: #{@errors.full_messages.join(", ")}"
      end
    end

    # This error is raised when trying to access a Mongo::Collection from an
    # embedded document.
    #
    # Example:
    #
    # <tt>InvalidCollection.new(Address)</tt>
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

    # This error is raised when trying to create a field that conflicts with
    # a Mongoid internal attribute or method.
    #
    # Example:
    #
    # <tt>InvalidField.new('collection')</tt>
    class InvalidField < RuntimeError
      def initialize(name)
        @name = name
      end
      def message
        "Defining a field named '#{@name}' is not allowed. " +
          "Do not define fields that conflict with Mongoid internal attributes " +
          "or method names. Use Document#instance_methods to see what " +
          "names this includes."
      end
    end
  end
end
