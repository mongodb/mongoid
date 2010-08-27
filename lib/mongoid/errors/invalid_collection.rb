# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when trying to access a Mongo::Collection from an
    # embedded document.
    #
    # Example:
    #
    # <tt>InvalidCollection.new(Address)</tt>
    class InvalidCollection < MongoidError
      def initialize(klass)
        super(
          translate("invalid_collection", { :klass => klass.name })
        )
      end
    end
  end
end
