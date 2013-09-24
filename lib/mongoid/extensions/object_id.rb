# encoding: utf-8
module Mongoid
  module Extensions
    module ObjectId

      # Evolve the object id.
      #
      # @example Evolve the object id.
      #   object_id.__evolve_object_id__
      #
      # @return [ BSON::ObjectId ] self.
      #
      # @since 3.0.0
      def __evolve_object_id__
        self
      end
      alias :__mongoize_object_id__ :__evolve_object_id__

      module ClassMethods

        # Evolve the object into a mongo-friendly value to query with.
        #
        # @example Evolve the object.
        #   ObjectId.evolve(id)
        #
        # @param [ Object ] object The object to evolve.
        #
        # @return [ BSON::ObjectId ] The object id.
        #
        # @since 3.0.0
        def evolve(object)
          object.__evolve_object_id__
        end

        # Convert the object into a mongo-friendly value to store.
        #
        # @example Convert the object.
        #   ObjectId.mongoize(id)
        #
        # @param [ Object ] object The object to convert.
        #
        # @return [ BSON::ObjectId ] The object id.
        #
        # @since 3.0.0
        def mongoize(object)
          object.__mongoize_object_id__
        end
      end
    end
  end
end

BSON::ObjectId.__send__(:include, Mongoid::Extensions::ObjectId)
BSON::ObjectId.__send__(:extend, Mongoid::Extensions::ObjectId::ClassMethods)
