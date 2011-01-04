# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # Superclass for all objects that bind relations together.
    class Binding
      attr_reader :base, :target, :metadata

      # Convenience method for calling a method only if it exists on the
      # object.
      #
      # @example Attempt the method.
      #   binding.attempt(inverse, target)
      #
      # @param [ String, Symbol ] method The name of the method.
      # @param [ Object ] object The object to attempt on.
      #
      # @return [ Object ] The result of the call.
      #
      # @since 2.0.0.rc.1
      def attempt(method, object, *args)
        object.send(method, *args) if object.respond_to?(method)
      end

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

      # Convenience method for getting a reference to myself off the inverse
      # relation, ie this object as referenced from the other side.
      #
      # @example Get the inverse relation.
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
      # @return [ Document ] The inverse relation.
      #
      # @since 2.0.0.rc.1
      def inverse
        name = metadata.inverse(target)
        target.to_a.first.ivar(name)
      end
    end
  end
end
