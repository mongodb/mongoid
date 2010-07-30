# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when invalid options are passed into a constructor or method.
    #
    # Example:
    #
    # <tt>InvalidOptions.new</tt>
    class InvalidOptions < MongoidError
      def initialize(key, options)
        super(translate(key, options))
      end
    end
  end
end
