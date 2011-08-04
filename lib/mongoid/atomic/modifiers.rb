# encoding: utf-8
module Mongoid #:nodoc:
  module Atomic #:nodoc:

    # This class contains the logic for supporting atomic operations against the
    # database.
    class Modifiers < Hash

      # Adds push modifiers to the modifiers hash.
      #
      # @example Add push operations.
      #   modifiers.push({ "addresses" => { "street" => "Bond" }})
      #
      # @param [ Hash ] modifications The push modifiers.
      #
      # @since 2.1.0
      def push(modifications)
        modifications.each_pair do |field, value|
          mods = conflicting?(field) ? conflicts : pushes
          if mods.has_key?(field)
            mods[field].push(value)
          else
            mods[field] = [ value ]
          end
        end
      end

      # Adds set operations to the modifiers hash.
      #
      # @example Add set operations.
      #   modifiers.set({ "title" => "sir" })
      #
      # @param [ Hash ] modifications The set modifiers.
      #
      # @since 2.1.0
      def set(modifications)
        modifications.each_pair do |field, value|
          next if field == "_id"
          sets.update(field => value)
          fields << field.split(".", 2)[0]
        end
      end

      private

      # Determines whether or not the provided field has a conflicting
      # modification with an already added $set operation.
      #
      # @example Does the field conflict?
      #   modifiers.conflicting?("addresses")
      #
      # @param [ String ] field The name of the field.
      #
      # @return [ true, false ] If the field conflicts.
      #
      # @since 2.1.0
      def conflicting?(field)
        fields.include?(field.split(".", 2)[0])
      end

      # Get the push operations that would have conflicted with the sets.
      #
      # @example Get the conflicts.
      #   modifiers.conflicts
      #
      # @return [ Hash ] The conflicting modifications.
      #
      # @since 2.1.0
      def conflicts
        self[:other] ||= {}
      end

      # Get the list of stripped fields that are being updated.
      #
      # @example Get the fields.
      #   modifiers.fields
      #
      # @return [ Array ] The stripped field names.
      #
      # @since 2.1.0
      def fields
        @fields ||= []
      end

      # Get the $pushAll operations or intialize a new one.
      #
      # @example Get the $pushAll operations.
      #   modifiers.pushes
      #
      # @return [ Hash ] The $pushAll operations.
      #
      # @since 2.1.0
      def pushes
        self["$pushAll"] ||= {}
      end

      # Get the $set operations or intialize a new one.
      #
      # @example Get the $set operations.
      #   modifiers.sets
      #
      # @return [ Hash ] The $set operations.
      #
      # @since 2.1.0
      def sets
        self["$set"] ||= {}
      end
    end
  end
end
