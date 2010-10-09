# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Binding #:nodoc

      attr_reader :base, :target, :metadata

      protected

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
        name = metadata.inverse(target)
        target.to_a.first.ivar(name)
      end
    end
  end
end
