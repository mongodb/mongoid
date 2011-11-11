# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when trying to load configuration with no RACK_ENV set
    class NoEnvironment < MongoidError
      def initialize
        super translate("no RACK_ENV set", {})
      end
    end
  end
end
