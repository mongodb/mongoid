# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Contextual

    # Mixin module included in Mongoid::Criteria which provides a
    # direct method interface to MongoDB's Update Operators ($set,
    # $pull, $inc, etc.) These operators can be applied to update
    # all documents in the database within the criteria scope,
    # without loading each document into Mongoid's memory.
    module Atomic

      # Execute an atomic $addToSet on the matching documents.
      #
      # @example Add the value to the set.
      #   context.add_to_set(members: "Dave", genres: "Electro")
      #
      # @param [ Hash ] adds The operations.
      #
      # @return [ nil ] Nil.
      def add_to_set(adds)
        view.update_many("$addToSet" => collect_operations(adds))
      end

      # Perform an atomic $addToSet/$each on the matching documents.
      #
      # @example Add the value to the set.
      #   context.add_each_to_set(members: ["Dave", "Bill"], genres: ["Electro", "Disco"])
      #
      # @param [ Hash ] adds The operations.
      #
      # @return [ nil ] Nil.
      def add_each_to_set(adds)
        view.update_many("$addToSet" => collect_each_operations(adds))
      end

      # Perform an atomic $bit operation on the matching documents.
      #
      # @example Perform the bitwise op.
      #   context.bit(likes: { and: 14, or: 4 })
      #
      # @param [ Hash ] bits The operations.
      #
      # @return [ nil ] Nil.
      def bit(bits)
        view.update_many("$bit" => collect_operations(bits))
      end

      # Perform an atomic $inc operation on the matching documents.
      #
      # @example Perform the atomic increment.
      #   context.inc(likes: 10)
      #
      # @param [ Hash ] incs The operations.
      #
      # @return [ nil ] Nil.
      def inc(incs)
        view.update_many("$inc" => collect_operations(incs))
      end

      # Perform an atomic $mul operation on the matching documents.
      #
      # @example Perform the atomic multiplication.
      #   context.mul(likes: 10)
      #
      # @param [ Hash ] factors The operations.
      #
      # @return [ nil ] Nil.
      def mul(factors)
        view.update_many("$mul" => collect_operations(factors))
      end

      # Perform an atomic $pop operation on the matching documents.
      #
      # @example Pop the first value on the matches.
      #   context.pop(members: -1)
      #
      # @example Pop the last value on the matches.
      #   context.pop(members: 1)
      #
      # @param [ Hash ] pops The operations.
      #
      # @return [ nil ] Nil.
      def pop(pops)
        view.update_many("$pop" => collect_operations(pops))
      end

      # Perform an atomic $pull operation on the matching documents.
      #
      # @example Pull the value from the matches.
      #   context.pull(members: "Dave")
      #
      # @note Expression pulling is not yet supported.
      #
      # @param [ Hash ] pulls The operations.
      #
      # @return [ nil ] Nil.
      def pull(pulls)
        view.update_many("$pull" => collect_operations(pulls))
      end

      # Perform an atomic $pullAll operation on the matching documents.
      #
      # @example Pull all the matching values from the matches.
      #   context.pull_all(:members, [ "Alan", "Vince" ])
      #
      # @param [ Hash ] pulls The operations.
      #
      # @return [ nil ] Nil.
      def pull_all(pulls)
        view.update_many("$pullAll" => collect_operations(pulls))
      end

      # Perform an atomic $push operation on the matching documents.
      #
      # @example Push the value to the matching docs.
      #   context.push(members: "Alan")
      #
      # @param [ Hash ] pushes The operations.
      #
      # @return [ nil ] Nil.
      def push(pushes)
        view.update_many("$push" => collect_operations(pushes))
      end

      # Perform an atomic $push/$each operation on the matching documents.
      #
      # @example Push the values to the matching docs.
      #   context.push_all(members: [ "Alan", "Fletch" ])
      #
      # @param [ Hash ] pushes The operations.
      #
      # @return [ nil ] Nil.
      def push_all(pushes)
        view.update_many("$push" => collect_each_operations(pushes))
      end

      # Perform an atomic $rename of fields on the matching documents.
      #
      # @example Rename the fields on the matching documents.
      #   context.rename(members: :artists)
      #
      # @param [ Hash ] renames The operations.
      #
      # @return [ nil ] Nil.
      def rename(renames)
        operations = renames.inject({}) do |ops, (old_name, new_name)|
          ops[old_name] = new_name.to_s
          ops
        end
        view.update_many("$rename" => collect_operations(operations))
      end

      # Perform an atomic $set of fields on the matching documents.
      #
      # @example Set the field value on the matches.
      #   context.set(name: "Depeche Mode")
      #
      # @param [ Hash ] sets The operations.
      #
      # @return [ nil ] Nil.
      def set(sets)
        view.update_many("$set" => collect_operations(sets))
      end

      # Perform an atomic $unset of a field on the matching documents.
      #
      # @example Unset the field on the matches.
      #   context.unset(:name)
      #
      # @param [ [ String | Symbol | Array<String | Symbol> | Hash ]... ] *unsets
      #   The name(s) of the field(s) to unset. If a Hash is specified,
      #   its keys will be used irrespective of value, even if the value
      #   is nil or false.
      #
      # @return [ nil ] Nil.
      def unset(*unsets)
        view.update_many('$unset' => collect_unset_operations(unsets))
      end

      # Performs an atomic $min update operation on the given field or fields.
      # Each field will be set to the minimum of [current_value, given value].
      # This has the effect of making sure that each field is no
      # larger than the given value; in other words, the given value is the
      # effective *maximum* for that field.
      #
      # @note Because of the existence of
      #   Mongoid::Contextual::Aggregable::Mongo#min, this method cannot be
      #   named #min, and thus breaks that convention of other similar methods
      #   of being named for the MongoDB operation they perform.
      #
      # @example Set "views" to be no more than 100.
      #   context.set_min(views: 100)
      #
      # @param [ Hash ] fields The fields with the maximum value that each
      #   may be set to.
      #
      # @return [ nil ] Nil.
      def set_min(fields)
        view.update_many("$min" => collect_operations(fields))
      end
      alias :clamp_upper_bound :set_min

      # Performs an atomic $max update operation on the given field or fields.
      # Each field will be set to the maximum of [current_value, given value].
      # This has the effect of making sure that each field is no
      # smaller than the given value; in other words, the given value is the
      # effective *minimum* for that field.
      #
      # @note Because of the existence of
      #   Mongoid::Contextual::Aggregable::Mongo#max, this method cannot be
      #   named #max, and thus breaks that convention of other similar methods
      #   of being named for the MongoDB operation they perform.
      #
      # @example Set "views" to be no less than 100.
      #   context.set_max(views: 100)
      #
      # @param [ Hash ] fields The fields with the minimum value that each
      #   may be set to.
      #
      # @return [ nil ] Nil.
      def set_max(fields)
        view.update_many("$max" => collect_operations(fields))
      end
      alias :clamp_lower_bound :set_max

      private

      # Collects and aggregates operations by field.
      #
      # @param [ Array | Hash ] ops The operations to collect.
      # @param [ Hash ] aggregator The hash to use to aggregate the operations.
      # 
      # @return [ Hash ] The aggregated operations, by field.
      def collect_operations(ops, aggregator = {})
        ops.each_with_object(aggregator) do |(field, value), operations|
          operations[database_field_name(field)] = value.mongoize
        end
      end

      def collect_each_operations(ops)
        ops.each_with_object({}) do |(field, value), operations|
          operations[database_field_name(field)] = { "$each" => Array.wrap(value).mongoize }
        end
      end

      # Builds the selector an atomic $unset operation from arguments.
      #
      # @example Prepare selector from array.
      #   context.collect_unset_operations([:name, :age])
      #   #=> { "name" => true, "age" => true }
      #
      # @example Prepare selector from hash.
      #   context.collect_unset_operations({ name: 1 }, { age: 1 })
      #   #=> { "name" => true, "age" => true }
      #
      # @param [ String | Symbol | Array<String | Symbol> | Hash ] ops
      #   The name(s) of the field(s) to unset.
      #
      # @return [ Hash ] The selector for the atomic $unset operation.
      def collect_unset_operations(ops)
        ops.map { |op| op.is_a?(Hash) ? op.keys : op }.flatten
           .map { |field| [database_field_name(field), true] }.to_h
      end
    end
  end
end
