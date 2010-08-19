# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Binding #:nodoc

      attr_reader :base, :target, :metadata

      protected

      # Determines if the supplied object is able to be bound - this is to
      # prevent infinite loops when setting inverse associations.
      #
      # Options:
      #
      # object: The object to check if it can be bound.
      #
      # Returns:
      #
      # true if bindable.
      def bindable?(object)
        !object.equal?(inverse ? inverse.target : nil)
      end

      # Create the new binding.
      #
      # Example:
      #
      # <tt>binding.init(base, target, metadata)<tt>
      #
      # Options:
      #
      # base: The base of the binding
      # target: The target of the binding.
      # metadata: The relation's metadata.
      def initialize(base, target, metadata)
        @base, @target, @metadata = base, target, metadata
      end

      # Convenience method for getting a reference to myself off the inverse
      # relation, ie this object as referenced from the other side.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     references_one :game
      #   end
      #
      #   class Game
      #     include Mongoid::Document
      #     referenced_in :person
      #   end
      #
      #   person.game.inverse # => returns the person.
      #
      # Returns:
      #
      # The inverse relation.
      def inverse
        target.send(metadata.inverse)
      end

      # Determines if the supplied object is able to be unbound - this is to
      # prevent infinite loops when setting inverse associations.
      #
      # Options:
      #
      # object: The object to check if it can be unbound.
      #
      # Returns:
      #
      # true if unbindable.
      def unbindable?(object)
        !object.send(metadata.foreign_key).nil?
      end
    end
  end
end
