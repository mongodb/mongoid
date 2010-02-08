# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    class CyclicIterator

      attr_reader :counter

      # Performs iteration over an array, if the array gets to the end then loop
      # back to the first.
      #
      # Example:
      #
      # <tt>CyclicIterator.new([ first, second ])</tt>
      def initialize(array)
        @array, @counter = array, -1
      end

      # Get the next element in the array. If the element is the last in the
      # array then return the first.
      #
      # Example:
      #
      # <tt>iterator.next</tt>
      #
      # Returns:
      #
      # The next element in the array.
      def next
        (@counter == @array.size - 1) ? @counter = 0 : @counter = @counter + 1
        @array[@counter]
      end
    end
  end
end
