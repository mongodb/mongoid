# frozen_string_literal: true

module Mongoid
  # A singleton class to assist with preparing attributes for atomic
  # updates.
  #
  # Once the deprecated Hash#__consolidate__ method is removed entirely,
  # these methods may be moved into Mongoid::Contextual::Mongo as private
  # methods.
  #
  # @api private
  class AtomicUpdatePreparer
    class << self
      # Convert the key/values in the attributes into a hash of atomic updates.
      # Non-operator keys are assumed to use $set operation.
      #
      # @param [ Class ] klass The model class.
      # @param [ Hash ] attributes The attributes to convert.
      #
      # @return [ Hash ] The prepared atomic updates.
      def prepare(attributes, klass)
        attributes.each_pair.with_object({}) do |(key, value), atomic_updates|
          key = klass.database_field_name(key.to_s)

          if key.to_s.start_with?('$')
            (atomic_updates[key] ||= {}).update(prepare_operation(klass, key, value))
          else
            (atomic_updates['$set'] ||= {})[key] = mongoize_for('$set', klass, key, value)
          end
        end
      end

      private

      # Treats the key as if it were a MongoDB operator and prepares
      # the value accordingly.
      #
      # @param [ Class ] klass the model class
      # @param [ String | Symbol ] key the operator
      # @param [ Hash ] value the operand
      #
      # @return [ Hash ] the prepared value.
      def prepare_operation(klass, key, value)
        value.each_with_object({}) do |(key2, value2), hash|
          key2 = klass.database_field_name(key2)
          hash[key2] = value_for(key, klass, key2, value2)
        end
      end

      # Get the value for the provided operator, klass, key and value.
      #
      # This is necessary for special cases like $rename, $addToSet, $push, $pull and $pop.
      #
      # @param [ String ] operator The operator.
      # @param [ Class ] klass The model class.
      # @param [ String | Symbol ] key The field key.
      # @param [ Object ] value The original value.
      #
      # @return [ Object ] Value prepared for the provided operator.
      def value_for(operator, klass, key, value)
        case operator
        when '$rename' then value.to_s
        when '$addToSet', '$push', '$pull', '$pop' then value.mongoize
        else mongoize_for(operator, klass, key, value)
        end
      end

      # Mongoize for the klass, key and value.
      #
      # @param [ String ] operator The operator.
      # @param [ Class ] klass The model class.
      # @param [ String | Symbol ] key The field key.
      # @param [ Object ] value The value to mongoize.
      #
      # @return [ Object ] The mongoized value.
      def mongoize_for(operator, klass, key, value)
        field = klass.fields[key.to_s]
        return value unless field

        mongoized = field.mongoize(value)
        if Mongoid::Persistable::LIST_OPERATIONS.include?(operator) && field.resizable? && !value.is_a?(Array)
          return mongoized.first
        end

        mongoized
      end
    end
  end
end
