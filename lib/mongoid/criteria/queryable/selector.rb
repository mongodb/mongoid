# frozen_string_literal: true

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
        # @param [ Hash | Selector ] other The object to merge in.
        #
        # @return [ Selector ] The selector.
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
        # @param [ String | Symbol ] key The name of the attribute.
        # @param [ Object ] value The value to add.
        #
        # @return [ Object ] The stored object.
        def store(key, value)
          name, serializer = storage_pair(key)
          if multi_selection?(name)
            store_name = name
            store_value = evolve_multi(value)
          else
            store_name, store_value = store_creds(name, serializer, value)
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
        def to_pipeline
          pipeline = []
          pipeline.push({ "$match" => self }) unless empty?
          pipeline
        end

        private

        # Get the store name and store value. If the value is of type range,
        # we need may need to change the store_name as well as the store_value,
        # therefore, we cannot just use the evole method.
        #
        # @param [ String ] name The name of the field.
        # @param [ Object ] serializer The optional serializer for the field.
        # @param [ Object ] value The value to serialize.
        #
        # @return [ Array<String, String> ] The store name and store value.
        def store_creds(name, serializer, value)
          store_name = localized_key(name, serializer)
          if Range === value
            evolve_range(store_name, serializer, value)
          else
            [ store_name, evolve(serializer, value) ]
          end
        end

        # Evolves a multi-list selection, like an $and or $or criterion, and
        # performs the necessary serialization.
        #
        # @example Evolve the multi-selection.
        #   selector.evolve_multi([{ field: "value" }])
        #
        # @param [ Array<Hash> ] specs The multi-selection.
        #
        # @return [ Array<Hash> ] The serialized values.
        #
        # @api private
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
              # This performs type conversions on the value and transformations
              # that depend on the type of the field that the value is stored
              # in, but not transformations that have to do with query shape.
              final_key, evolved_value = store_creds(name, serializer, value)

              # This builds a query shape around the value, when the query
              # involves complex keys. For example, {:foo.lt => 5} produces
              # {'foo' => {'$lt' => 5}}. This step should be done after all
              # value-based processing is complete.
              if key.is_a?(Key)
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
        def evolve(serializer, value)
          case value
          when Hash
            evolve_hash(serializer, value)
          when Array
            evolve_array(serializer, value)
          when Range
            value.__evolve_range__(serializer: serializer)
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
        def evolve_hash(serializer, value)
          value.each_pair do |operator, _value|
            if operator =~ /exists|type|size/
              value[operator] = _value
            else
              value[operator] = evolve(serializer, _value)
            end
          end
        end

        # Evolve a single key selection with range values. This method traverses
        # the association tree to build a query for the given value and
        # serializer. There are three parts to the query here:
        #
        # (1) "klass.child.gchild" => {
        #       "$elemMatch" => {
        #     (2) "ggchild.field" => (3) { "$gte" => 6, "$lte" => 10 }
        #       }
        #     }
        # (1) The first n fields are dotted together until the last
        #     embeds_many or field of type array. In the above case, gchild
        #     would be an embeds_many or Array, and ggchild would be an
        #     embeds_one or a hash.
        # (2) The last fields are used inside the $elemMatch. This one is
        #     actually optional, and will be ignored if the last field is an
        #     array or embeds_many. If the last field is an array (1), (2) and
        #     (3) will look like:
        #
        #       "klass.child.gchild.ggchild.field" => {
        #         { "$elemMatch" => { "$gte" => 6, "$lte" => 10 } }
        #       }
        #
        # (3) This is calculated by:
        #
        #       value.__evolve_range__(serializer: serializer).
        #
        # @api private
        #
        # @param [ String ] key The to store the range for.
        # @param [ Object ] serializer The optional serializer for the field.
        # @param [ Range ] value The Range to serialize.
        #
        # @return [ Array<String, Hash> ] The store name and serialized Range.
        def evolve_range(key, serializer, value)
          v = value.__evolve_range__(serializer: serializer)
          assocs = []
          Fields.traverse_association_tree(key, serializers, associations, aliased_associations) do |meth, obj, is_field|
            assocs.push([meth, obj, is_field])
          end

          # Iterate backwards until you get a field with type
          # Array or an embeds_many association.
          inner_key = ""
          loop do
            # If there are no arrays or embeds_many associations, just return
            # the key and value without $elemMatch.
            return [ key, v ] if assocs.empty?

            meth, obj, is_field = assocs.last
            break if (is_field && obj.type == Array) || (!is_field && obj.is_a?(Association::Embedded::EmbedsMany))

            assocs.pop
            inner_key = "#{meth}.#{inner_key}"
          end

          # If the last array or embeds_many association is the last field,
          # the inner key (2) is ignored, and the outer key (1) is the original
          # key.
          if inner_key.blank?
            [ key, { "$elemMatch" => v }]
          else
            store_key = assocs.map(&:first).join('.')
            store_value = { "$elemMatch" => { inner_key.chop => v } }
            [ store_key,  store_value ]
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
        # @return [ true | false ] If the key is for a multi-select.
        def multi_selection?(key)
          %w($and $or $nor).include?(key)
        end
      end
    end
  end
end
