# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Enumerable
      attr_reader :selector, :options, :documents

      # Create the new enumerable context. This will need the selector and
      # options from a +Criteria+ and a documents array that is the underlying
      # array of embedded documents from a has many association.
      #
      # Example:
      #
      # <tt>Mongoid::Contexts::Enumerable.new(selector, options, docs)</tt>
      def initialize(selector, options, documents)
        @selector, @options, @documents = selector, options, documents
      end

      # Enumerable implementation of execute. Returns matching documents for
      # the selector, and adds options if supplied.
      def execute
        @documents.select { |document| document.matches?(@selector) }
      end
    end
  end
end
