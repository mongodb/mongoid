# encoding: utf-8
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
      #
      # @since 3.0.0
      def add_to_set(adds)
        view.update_many("$addToSet" => collect_operations(adds))
      end

      # Perform an atomic $bit operation on the matching documents.
      #
      # @example Perform the bitwise op.
      #   context.bit(likes: { and: 14, or: 4 })
      #
      # @param [ Hash ] bits The operations.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
      def push(pushes)
        view.update_many("$push" => collect_operations(pushes))
      end

      # Perform an atomic $pushAll operation on the matching documents.
      #
      # @example Push the values to the matching docs.
      #   context.push(members: [ "Alan", "Fletch" ])
      #
      # @param [ Hash ] pushes The operations.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
      def push_all(pushes)
        view.update_many("$pushAll" => collect_operations(pushes))
      end

      # Perform an atomic $rename of fields on the matching documents.
      #
      # @example Rename the fields on the matching documents.
      #   context.rename(members: :artists)
      #
      # @param [ Hash ] renames The operations.
      #
      # @return [ nil ] Nil.
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
      def set(sets)
        view.update_many("$set" => collect_operations(sets))
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
        view.update_many("$unset" => Hash[fields])
      end

      private

      def collect_operations(ops)
        ops.inject({}) do |operations, (field, value)|
          operations[database_field_name(field)] = value.mongoize
          operations
        end
      end
    end
  end
end
