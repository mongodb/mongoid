# frozen_string_literal: true

module Mongoid
  module Contextual
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
      # @param [ [ String | Symbol | Array<String | Symbol> | Hash ]... ] *args
      #   The name(s) of the field(s) to unset.
      #   If a Hash is specified, its keys will be used irrespective of what
      #   each key's value is, even if the value is nil or false.
      #
      # @return [ nil ] Nil.
      def unset(*args)
        fields = args.map { |a| a.is_a?(Hash) ? a.keys : a }
                     .__find_args__
                     .map { |f| [database_field_name(f), true] }
        view.update_many("$unset" => Hash[fields])
      end

      # Performs an atomic $currentDate operation on the given field or fields.
      #
      # @example Set the "last viewed" timestamp.
      #   context.current_date(last_viewed: :timestamp)
      #
      # @example Set the completion date.
      #   context.current_date(:completed)
      #   # or
      #   context.current_date(completed: true)
      #
      # @example Set multiple fields to the current date.
      #   context.current_date(:completed, last_viewed: :timestamp)
      #
      # @param [ Array<Hash | Symbol | String> ] fields The fields with the
      #   corresponding date format to use (true, :timestamp, or :date)
      #
      # @return [ nil ] Nil.
      def current_date(*fields)
        fields = collect_nested_operations(fields) { |value| translate_date_type(value) }
        view.update_many("$currentDate" => fields)
      end

      # Performs an atomic $min update operation on the given field or fields.
      #
      # @note Because of the existence of
      #   Mongoid::Contextual::Aggregable::Mongo#min, this method cannot be
      #   named #min, and thus breaks that convention of other similar methods
      #   of being named for the MongoDB operation they perform.
      #
      # @example Set "views" to be no more than 100.
      #   context.update_min(views: 100)
      #
      # @example Set multiple fields to the current date.
      #   context.current_date(:completed, last_viewed: :timestamp)
      #
      # @param [ Hash ] fields The fields with the maximum value that each
      #   may be set to.
      #
      # @return [ nil ] Nil.
      def update_min(fields)
        view.update_many("$min" => collect_operations(fields))
      end

      private

      # Collects nested operations, where `ops` is assumed to be an array of
      # Arrays, Hashes, Symbols, or Strings.
      #
      # @param [ Array<Hash | Array | Symbol | String> ] ops The operations
      #   to collect
      #
      # @return [ Hash ] The aggregated operations, by field.
      def collect_nested_operations(ops, &translator)
        ops.each_with_object({}) do |item, aggregator|
          collect_operations(Array(item), aggregator, &translator)
        end
      end

      # Collects and aggregates operations by field.
      #
      # @param [ Array | Hash ] ops The operations to collect.
      # @param [ Hash ] aggregator The hash to use to aggregate the operations.
      # 
      # @return [ Hash ] The aggregated operations, by field.
      def collect_operations(ops, aggregator = {}, &translator)
        translator ||= ->(v) { v }
        ops.each_with_object(aggregator) do |(field, value), operations|
          operations[database_field_name(field)] = translator[value.mongoize]
        end
      end

      def collect_each_operations(ops)
        ops.each_with_object({}) do |(field, value), operations|
          operations[database_field_name(field)] = { "$each" => Array.wrap(value).mongoize }
        end
      end

      def translate_date_type(type)
        Mongoid::Persistable::Datable.translate_date_field_spec(type)
      end
    end
  end
end
