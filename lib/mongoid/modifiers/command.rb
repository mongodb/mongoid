# encoding: utf-8
module Mongoid #:nodoc:
  module Modifiers #:nodoc:
    class Command #:nodoc:
      include Mongoid::Safe

      # Instantiate the new $inc modifier.
      #
      # Options:
      #
      # klass: The class to get the collection from.
      # options: The options to get passed through to the driver.
      def initialize(document, options = {})
        @document, @options = document, options
      end
    end
  end
end
