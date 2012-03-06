# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # Superclass for all objects that bind relations together.
    class Binding
      include Threaded::Lifecycle

      attr_reader :base, :target, :metadata

      # Create the new binding.
      #
      # @example Initialize a binding.
      #   Binding.new(base, target, metadata)
      #
      # @param [ Document ] base The base of the binding.
      # @param [ Document, Array<Document> ] target The target of the binding.
      # @param [ Metadata ] metadata The relation's metadata.
      #
      # @since 2.0.0.rc.1
      def initialize(base, target, metadata)
        @base, @target, @metadata = base, target, metadata
      end

      # Execute the provided block inside a binding.
      #
      # @example Execute the binding block.
      #   binding.binding do
      #     base.foreign_key = 1
      #   end
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 3.0.0
      def binding
        unless _binding?
          _binding do
            yield(self) if block_given?
          end
        end
      end
    end
  end
end
