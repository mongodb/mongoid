# encoding: utf-8
module Mongoid
  module Errors

    # Raised when the database connection has not been set up properly, either
    # by attempting to set an object on the db that is not a +Mongo::DB+, or
    # not setting anything at all.
    #
    # @example Create the error.
    #   InvalidDatabase.new("Not a DB")
    class InvalidDatabase < MongoidError
      def initialize(database)
        super(
          compose_message("invalid_database", { name: database.class.name })
        )
      end
    end
  end
end
