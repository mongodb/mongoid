# frozen_string_literal: true

module Mongoid
  module Extensions
    # Adds type-casting behavior to BSON::Vector class so that a field
    # declared with +type: BSON::Vector+ is stored as a BSON binary of the
    # vector subtype and read back as a BSON::Vector.
    #
    # Querying by an exact vector value (e.g. +where(embedding: vector)+) is
    # not supported: BSON::Vector subclasses Array, so the criteria selector
    # treats it as a list of elements rather than a scalar. Use Atlas Vector
    # Search ($vectorSearch) for similarity queries on vector fields.
    module Vector
      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ BSON::Binary | nil ] The object as a vector binary.
      def mongoize
        BSON::Vector.mongoize(self)
      end

      module ClassMethods
        # Mongoize an object of any type to how it's stored in the db.
        #
        # @example Mongoize the object.
        #   BSON::Vector.mongoize(vector)
        #
        # @param [ Object ] object The object to Mongoize.
        #
        # @return [ BSON::Binary | nil ] A vector binary or nil.
        def mongoize(object)
          case object
          when BSON::Vector then BSON::Binary.from_vector(object)
          when BSON::Binary then object
          end
        end

        # Convert the object from its mongo friendly ruby type back to a
        # BSON::Vector.
        #
        # @example Demongoize the object.
        #   BSON::Vector.demongoize(binary)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ BSON::Vector | nil ] The vector or nil.
        def demongoize(object)
          case object
          when BSON::Binary then (object.type == :vector) ? object.as_vector : nil
          when BSON::Vector then object
          end
        end
      end
    end
  end
end

if defined?(BSON::Vector)
  BSON::Vector.include Mongoid::Extensions::Vector
  BSON::Vector.extend(Mongoid::Extensions::Vector::ClassMethods)
end
