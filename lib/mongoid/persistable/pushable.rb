# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $push and $addToSet operations.
    #
    # @since 4.0.0
    module Pushable
      extend ActiveSupport::Concern

      # Add the single values to the arrays only if the value does not already
      # exist in the array.
      #
      # @example Add the values to the sets.
      #   document.add_to_set(names: "James", aliases: "Bond")
      #
      # @param [ Hash ] adds The field/value pairs to add.
      #
      # @return [ Document ] The document.
      #
      # @since 4.0.0
      def add_to_set(adds)
        prepare_atomic_operation do |ops|
          process_atomic_operations(adds) do |field, value|
            existing = send(field) || (attributes[field] ||= [])
            values = [ value ].flatten(1)
            values.each do |val|
              existing.push(val) unless existing.include?(val)
            end
            ops[atomic_attribute_name(field)] = { "$each" => values }
          end
          { "$addToSet" => ops }
        end
      end

      # Push a single value or multiple values onto arrays.
      #
      # @example Push a single value onto arrays.
      #   document.push(names: "James", aliases: "007")
      #
      # @example Push multiple values onto arrays.
      #   document.push(names: [ "James", "Bond" ])
      #
      # @param [ Hash ] pushes The $push operations.
      #
      # @return [ Document ] The document.
      #
      # @since 4.0.0
      def push(pushes)
        prepare_atomic_operation do |ops|
          process_atomic_operations(pushes) do |field, value|
            existing = send(field) || (attributes[field] ||= [])
            values = [ value ].flatten(1)
            values.each{ |val| existing.push(val) }
            ops[atomic_attribute_name(field)] = { "$each" => values }
          end
          { "$push" => ops }
        end
      end
    end
  end
end
