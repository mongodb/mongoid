# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $push and $addToSet operations.
    #
    # @since 4.0.0
    module Pushable
      extend ActiveSupport::Concern

      # def add_to_set(adds)
      # end

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
      # @return [ true, false ] If the operation succeeded.
      #
      # @since 4.0.0
      def push(pushes)
        prepare_atomic_operation do |coll, selector, ops|
          process_atomic_operations(pushes) do |field, value|
            existing = send(field) || []
            values = [ value ].flatten
            values.each{ |val| existing.push(val) }
            send("#{field}=", existing)
            ops[atomic_attribute_name(field)] = { "$each" => values }
          end
          coll.find(selector).update(positionally(selector, "$push" => ops))
        end
      end
    end
  end
end
