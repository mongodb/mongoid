#encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when you don't allow dynamic fields and try to assign a non attribute value
    class UnknownAttributeError < MongoidError
    end
  end
end
