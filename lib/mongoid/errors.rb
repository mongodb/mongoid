# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Default parent Mongoid error for all custom errors
    class MongoidError < StandardError; end

    # Raised when querying the database for a document by a specific id which
    # does not exist. If multiple ids were passed then it will display all of
    # those.
    #
    # Example:
    #
    # <tt>DocumentNotFound.new(Person, ["1", "2"])</tt>
    class DocumentNotFound < MongoidError
      attr_reader :klass, :indentifiers
      def initialize(klass, ids)
        @klass = klass
        @identifiers = ids.is_a?(Array) ? ids.join(", ") : ids
        super("Document not found for class #{@klass} with id(s) #{@identifiers}")
      end
    end

    # Raised when invalid options are passed into a constructor or method.
    #
    # Example:
    #
    # <tt>InvalidOptions.new</tt>
    class InvalidOptions < MongoidError; end

    # Raised when the database connection has not been set up properly, either
    # by attempting to set an object on the db that is not a +Mongo::DB+, or
    # not setting anything at all.
    #
    # Example:
    #
    # <tt>InvalidDatabase.new("Not a DB")</tt>
    class InvalidDatabase < MongoidError
      attr_reader :database
      def initialize(database)
        @database = database
        super("Database should be a Mongo::DB, not #{@database.class.name}")
      end
    end

    # Raised when trying to get or set a value for a defined field, where the
    # type of the object does not match the defined field type.
    #
    # Example:
    #
    # <tt>InvalidType.new(Array, "Not an Array")</tt>
    class InvalidType < MongoidError
      def initialize(klass, value)
        super("Field was defined as a(n) #{klass.name}, but received a #{value.class.name} " +
              "with the value #{value.inspect}.")
      end
    end

    # Raised when the database version is not supported by Mongoid.
    #
    # Example:
    #
    # <tt>UnsupportedVersion.new(Mongo::ServerVersion.new("1.3.1"))</tt>
    class UnsupportedVersion < MongoidError
      def initialize(version)
        super("MongoDB #{version} not supported, please upgrade to #{Mongoid::MONGODB_VERSION}")
      end
    end

    # Raised when a persisence method ending in ! fails validation. The message
    # will contain the full error messages from the +Document+ in question.
    #
    # Example:
    #
    # <tt>Validations.new(person.errors)</tt>
    class Validations < MongoidError
      attr_reader :document
      def initialize(document)
        @document = document
        super("Validation Failed: #{@document.errors.full_messages.join(", ")}")
      end
    end

    # This error is raised when trying to access a Mongo::Collection from an
    # embedded document.
    #
    # Example:
    #
    # <tt>InvalidCollection.new(Address)</tt>
    class InvalidCollection < MongoidError
      attr_reader :klass
      def initialize(klass)
        @klass = klass
        super("Access to the collection for #{@klass.name} is not allowed " +
              "since it is an embedded document, please access a collection from " +
              "the root document")
      end
    end

    # This error is raised when trying to create a field that conflicts with
    # a Mongoid internal attribute or method.
    #
    # Example:
    #
    # <tt>InvalidField.new('collection')</tt>
    class InvalidField < MongoidError
      attr_reader :name
      def initialize(name)
        @name = name
        super("Defining a field named '#{@name}' is not allowed. " +
              "Do not define fields that conflict with Mongoid internal attributes " +
              "or method names. Use Document#instance_methods to see what " +
              "names this includes.")
      end
    end

    # This error is raised when trying to create set nested records above the
    # specified :limit
    #
    # Example:
    #
    #<tt>TooManyNestedAttributeRecords.new('association', limit)
    class TooManyNestedAttributeRecords < MongoidError
      attr_reader :association, :limit
      def initialize(association, limit)
        @association, @limit = association.to_s.humanize.capitalize, limit
        super("Accept Nested Attributes for #{@association} is limited to #{@limit} records")
      end
    end
  end
end
