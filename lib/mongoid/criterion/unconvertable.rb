# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # Wrapper class for strings that should not be converted into
    # BSON::ObjectIds.
    class Unconvertable < String

      # Initialize just like a normal string, and quack like it to.
      #
      # @example Create the new Unconvertable.
      #   Unconvertable.new("testing")
      #
      # @param [ String ] value The string.
      #
      # @since 2.0.2
      def initialize(value); super; end
    end
  end
end
