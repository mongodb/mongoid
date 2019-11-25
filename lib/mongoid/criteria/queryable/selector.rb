# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  class Criteria
    module Queryable

      # The selector is a special kind of hash that knows how to serialize values
      # coming into it as well as being alias and locale aware for key names.
      class Selector < Smash

        # Merges another selector into this one.
        #
        # @example Merge in another selector.
        #   selector.merge!(name: "test")
        #
        # @param [ Hash, Selector ] other The object to merge in.
        #
        # @return [ Selector ] The selector.
        #
        # @since 1.0.0
        def merge!(other)
          other.each_pair do |key, value|
            if value.is_a?(Hash) && self[key.to_s].is_a?(Hash)
              value = self[key.to_s].merge(value) do |_key, old_val, new_val|
                case _key
                when '$in'
                  new_val & old_val
                when '$nin'
                  (old_val + new_val).uniq
                else
                  new_val
                end
              end
            end
            if multi_selection?(key)
              value = (self[key.to_s] || []).concat(value)
            end
            store(key, value)
          end
        end

        # Store the value in the selector for the provided key. The selector will
        # handle all necessary serialization and localization in this step.
        #
        # @example Store a value in the selector.
        #   selector.store(:key, "testing")
        #
        # @param [ String, Symbol ] key The name of the attribute.
        # @param [ Object ] value The value to add.
        #
        # @return [ Object ] The stored object.
        #
        # @since 1.0.0
        def store(key, value)
          name, serializer = storage_pair(key)
          if multi_selection?(name)
            store_name = name
            store_value = evolve_multi(value)
          else
            store_name = localized_key(name, serializer)
            store_value = evolve(serializer, value)
          end
          super(store_name, store_value)
        end
        alias :[]= :store

        # Convert the selector to an aggregation pipeline entry.
        #
        # @example Convert the selector to a pipeline.
        #   selector.to_pipeline
        #
        # @return [ Array<Hash> ] The pipeline entry for the selector.
        #
        # @since 2.0.0
        def to_pipeline
          pipeline = []
          pipeline.push({ "$match" => self }) unless empty?
          pipeline
        end

        private

        # Evolves a multi-list selection, like an $and or $or criterion, and
        # performs the necessary serialization.
        #
        # @api private
        #
        # @example Evolve the multi-selection.
        #   selector.evolve_multi([{ field: "value" }])
        #
        # @param [ Array<Hash> ] value The multi-selection.
        #
        # @return [ Array<Hash> ] The serialized values.
        #
        # @since 1.0.0
        def evolve_multi(specs)
          unless specs.is_a?(Array)
            raise ArgumentError, "specs is not an array: #{specs.inspect}"
          end
          specs.map do |spec|
            Hash[spec.map do |key, value|
              # If an application nests conditionals, e.g.
              # {'$or' => [{'$or' => {...}}]},
              # when evolve_multi is called for the top level hash,
              # this call recursively transforms the bottom level $or.
              if multi_selection?(key)
                value = evolve_multi(value)
              end

              # storage_pair handles field aliases but not localization for
              # some reason, although per its documentation Smash supposedly
              # owns both.
              name, serializer = storage_pair(key)
              final_key = localized_key(name, serializer)
              # This performs type conversions on the value and transformations
              # that depend on the type of the field that the value is stored
              # in, but not transformations that have to do with query shape.
              evolved_value = evolve(serializer, value)

              # This builds a query shape around the value, when the query
              # involves complex keys. For example, {:foo.lt => 5} produces
              # {'foo' => {'$lt' => 5}}. This step should be done after all
              # value-based processing is complete.
              if key.is_a?(Key)
                if serializer && evolved_value != value
                  raise NotImplementedError, "This method is not prepared to handle key being a Key and serializer being not nil"
                end

                evolved_value = key.transform_value(evolved_value)
              end

              [ final_key, evolved_value ]
            end]
          end.uniq
        end

        # Evolve a single key selection with various types of values.
        #
        # @api private
        #
        # @example Evolve a simple selection.
        #   selector.evolve(field, 5)
        #
        # @param [ Object ] serializer The optional serializer for the field.
        # @param [ Object ] value The value to serialize.
        #
        # @return [ Object ] The serialized object.
        #
        # @since 1.0.0
        def evolve(serializer, value)
          case value
          when Hash
            evolve_hash(serializer, value)
          when Array
            evolve_array(serializer, value)
          else
            (serializer || value.class).evolve(value)
          end
        end

        # Evolve a single key selection with array values.
        #
        # @api private
        #
        # @example Evolve a simple selection.
        #   selector.evolve(field, [ 1, 2, 3 ])
        #
        # @param [ Object ] serializer The optional serializer for the field.
        # @param [ Array<Object> ] value The array to serialize.
        #
        # @return [ Object ] The serialized array.
        #
        # @since 1.0.0
        def evolve_array(serializer, value)
          value.map do |_value|
            evolve(serializer, _value)
          end
        end

        # Evolve a single key selection with hash values.
        #
        # @api private
        #
        # @example Evolve a simple selection.
        #   selector.evolve(field, { "$gt" => 5 })
        #
        # @param [ Object ] serializer The optional serializer for the field.
        # @param [ Hash ] value The hash to serialize.
        #
        # @return [ Object ] The serialized hash.
        #
        # @since 1.0.0
        def evolve_hash(serializer, value)
          value.each_pair do |operator, _value|
            if operator =~ /exists|type|size/
              value[operator] = _value
            else
              value[operator] = evolve(serializer, _value)
            end
          end
        end

        # Determines if the selection is a multi-select, like an $and or $or or $nor
        # selection.
        #
        # @api private
        #
        # @example Is the selection a multi-select?
        #   selector.multi_selection?("$and")
        #
        # @param [ String ] key The key to check.
        #
        # @return [ true, false ] If the key is for a multi-select.
        #
        # @since 1.0.0
        def multi_selection?(key)
          %w($and $or $nor).include?(key)
        end
      end
    end
  end
end
