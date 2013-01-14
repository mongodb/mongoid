# encoding: utf-8
module Mongoid
  module Contextual
    module Atomic

      # Execute an atomic $addToSet on the matching documents.
      #
      # @example Add the value to the set.
      #   context.add_to_set(:members, "Dave")
      #
      # @param [ String, Symbol ] field The name of the field to add to.
      # @param [ Object ] value The single value to add.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def add_to_set(field, value)
        query.update_all("$addToSet" => { database_field_name(field) => value })
      end

      # Perform an atomic $bit operation on the matching documents.
      #
      # @example Perform the bitwise op.
      #   context.bit(:likes, { and: 14, or: 4 })
      #
      # @param [ String, Symbol ] field The name of the field to operate on.
      # @param [ Hash ] value The bitwise operations to perform. Keys may be
      #   "and" or "or" and must have numeric values.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def bit(field, value)
        query.update_all("$bit" => { database_field_name(field) => value })
      end

      # Perform an atomic $inc operation on the matching documents.
      #
      # @example Perform the atomic increment.
      #   context.inc(:likes, 10)
      #
      # @param [ String, Symbol ] field The field to increment.
      # @param [ Integer ] value The amount to increment by.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def inc(field, value)
        query.update_all("$inc" => { database_field_name(field) => value })
      end

      # Perform an atomic $pop operation on the matching documents.
      #
      # @example Pop the first value on the matches.
      #   context.pop(:members, -1)
      #
      # @example Pop the last value on the matches.
      #   context.pop(:members, 1)
      #
      # @param [ String, Symbol ] field The name of the array field to pop
      #   from.
      # @param [ Integer ] value 1 to pop from the end, -1 to pop from the
      #   front.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def pop(field, value)
        query.update_all("$pop" => { database_field_name(field) => value })
      end

      # Perform an atomic $pull operation on the matching documents.
      #
      # @example Pull the value from the matches.
      #   context.pull(:members, "Dave")
      #
      # @note Expression pulling is not yet supported.
      #
      # @param [ String, Symbol ] field The field to pull from.
      # @param [ Object ] value The single value to pull.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def pull(field, value)
        query.update_all("$pull" => { database_field_name(field) => value })
      end

      # Perform an atomic $pullAll operation on the matching documents.
      #
      # @example Pull all the matching values from the matches.
      #   context.pull_all(:members, [ "Alan", "Vince" ])
      #
      # @param [ String, Symbol ] field The field to pull from.
      # @param [ Array<Object> ] values The values to pull.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def pull_all(field, values)
        query.update_all("$pullAll" => { database_field_name(field) => values })
      end

      # Perform an atomic $push operation on the matching documents.
      #
      # @example Push the value to the matching docs.
      #   context.push(:members, "Alan")
      #
      # @param [ String, Symbol ] field The field to push to.
      # @param [ Object ] value The value to push.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def push(field, value)
        query.update_all("$push" => { database_field_name(field) => value })
      end

      # Perform an atomic $pushAll operation on the matching documents.
      #
      # @example Push the values to the matching docs.
      #   context.push(:members, [ "Alan", "Fletch" ])
      #
      # @param [ String, Symbol ] field The field to push to.
      # @param [ Array<Object> ] values The values to push.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def push_all(field, values)
        query.update_all("$pushAll" => { database_field_name(field) => values })
      end

      # Perform an atomic $rename of fields on the matching documents.
      #
      # @example Rename the fields on the matching documents.
      #   context.rename(:members, :artists)
      #
      # @param [ String, Symbol ] old_name The old field name.
      # @param [ String, Symbol ] new_name The new field name.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def rename(old_name, new_name)
        query.update_all("$rename" => { database_field_name(old_name) => new_name.to_s })
      end

      # Perform an atomic $set of fields on the matching documents.
      #
      # @example Set the field value on the matches.
      #   context.set(:name, "Depeche Mode")
      #
      # @param [ String, Symbol ] field The name of the field.
      # @param [ Object ] value The value to set.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def set(field, value)
        query.update_all("$set" => { database_field_name(field) => value })
      end

      # Perform an atomic $unset of a field on the matching documents.
      #
      # @example Unset the field on the matches.
      #   context.unset(:name)
      #
      # @param [ String, Symbol, Array ] fields The name of the fields.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def unset(*args)
        fields = args.__find_args__.collect { |f| [database_field_name(f), true] }
        query.update_all("$unset" => Hash[fields])
      end
    end
  end
end
