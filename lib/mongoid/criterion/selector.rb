# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:

    # The selector is a hash-like object that has special behaviour for merging
    # mongoid criteria selectors.
    class Selector < Hash

      attr_reader :aliased_fields, :fields, :klass

      # Create the new selector.
      #
      # @example Create the selector.
      #   Selector.new(Person)
      #
      # @param [ Class ] klass The class the selector is for.
      #
      # @since 1.0.0
      def initialize(klass)
        @aliased_fields, @fields, @klass =
          klass.aliased_fields, klass.fields.except("_id", "_type"), klass
      end

      # Set the value for the supplied key, attempting to typecast the value.
      #
      # @example Set the value for the key.
      #   selector["$ne"] = { :name => "Zorg" }
      #
      # @param [ String, Symbol ] key The hash key.
      # @param [ Object ] value The value to set.
      #
      # @since 2.0.0
      def []=(key, value)
        key = "#{key}.#{::I18n.locale}" if klass.fields[key.to_s].try(:localized?)
        super(key, try_to_typecast(key, value))
      end

      # Merge the selector with another hash.
      #
      # @example Merge the objects.
      #   selector.merge!({ :key => "value" })
      #
      # @param [ Hash, Selector ] other The object to merge with.
      #
      # @return [ Selector ] The merged selector.
      #
      # @since 1.0.0
      def merge!(other)
        tap do |selector|
          other.each_pair do |key, value|
            selector[key] = value
          end
        end
      end
      alias :update :merge!

      if RUBY_VERSION < '1.9'

        # Generate pretty inspection for old ruby versions.
        #
        # @example Inspect the selector.
        #   selector.inspect
        #
        # @return [ String ] The inspected selector.
        def inspect
          ret = self.keys.inject([]) do |ret, key|
            ret << "#{key.inspect}=>#{self[key].inspect}"
          end
          "{#{ret.sort.join(', ')}}"
        end
      end

      private

      # If the key is defined as a field, then attempt to typecast it.
      #
      # @example Try to cast.
      #   selector.try_to_typecast(:id, 1)
      #
      # @param [ String, Symbol ] key The field name.
      # @param [ Object ] value The value.
      #
      # @return [ Object ] The typecasted value.
      #
      # @since 1.0.0
      def try_to_typecast(key, value)
        access = key.to_s
        if field = fields[key.to_s] || fields[aliased_fields[key.to_s]]
          typecast_value_for(field, value)
        elsif proper_and_or_value?(key, value)
          handle_and_or_value(value)
        else
          value
        end
      end

      def proper_and_or_value?(key, value)
        ["$and", "$or"].include?(key) &&
          value.is_a?(Array) &&
          value.all?{ |e| e.is_a?(Hash) }
      end

      def handle_and_or_value(values)
        [].tap do |result|
           result.push(*values.map do |value|
            Hash[value.map do |_key, _value|
              if klass.fields[_key.to_s].try(:localized?)
                _key = "#{_key}.#{::I18n.locale}"
              end
              [_key, try_to_typecast(_key, _value)]
            end]
          end)
        end
      end

      # Get the typecast value for the defined field.
      #
      # @example Get the typecast value.
      #   selector.typecast_value_for(:name, "Corbin")
      #
      # @param [ Field ] field The defined field.
      # @param [ Object ] value The value to cast.
      #
      # @return [ Object ] The cast value.
      #
      # @since 1.0.0
      def typecast_value_for(field, value)
        return field.selection(value) if field.type === value
        case value
        when Hash
          value = value.dup
          value.each_pair do |k, v|
            value[k] = typecast_hash_value(field, k, v)
          end
        when Array
          value.map { |v| typecast_value_for(field, v) }
        when Regexp
          value
        when Range
          {
            "$gte" => typecast_value_for(field, value.first),
            "$lte" => typecast_value_for(field, value.last)
          }
        else
          if field.type == Array
            Serialization.mongoize(value, value.class)
          else
            field.selection(value)
          end
        end
      end

      # Typecast the value for booleans and integers in hashes.
      #
      # @example Typecast the hash values.
      #   selector.typecast_hash_value(field, "$exists", "true")
      #
      # @param [ Field ] field The defined field.
      # @param [ String ] key The modifier key.
      # @param [ Object ] value The value to cast.
      #
      # @return [ Object ] The cast value.
      #
      # @since 1.0.0
      def typecast_hash_value(field, key, value)
        case key
        when "$exists"
          Serialization.mongoize(value, Boolean)
        when "$size"
          Serialization.mongoize(value, Integer)
        else
          typecast_value_for(field, value)
        end
      end
    end
  end
end
