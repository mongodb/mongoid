# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when the database connection has not been set up properly, either
    # by attempting to set an object on the db that is not a +Mongo::DB+, or
    # not setting anything at all.
    #
    # Example:
    #
    # <tt>InvalidDatabase.new("Not a DB")</tt>
    class InvalidDatabase < MongoidError
      def initialize(database)
        super(
          translate("invalid_database", { :name => database.class.name })
        )
      end
    end
  end
end
