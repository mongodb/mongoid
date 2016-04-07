module Mongoid
  module Refinements

    refine BSON::ObjectId do

      # Evolve the object id.
      #
      # @example Evolve the object id.
      #   object_id.evolve_object_id
      #
      # @return [ BSON::ObjectId ] self.
      #
      # @since 6.0.0
      def evolve_object_id; self; end
      alias :mongoize_object_id :evolve_object_id
    end

    refine BSON::ObjectId.singleton_class do

      # Evolve the object into a mongo-friendly value to query with.
      #
      # @example Evolve the object.
      #   ObjectId.evolve(id)
      #
      # @param [ Object ] object The object to evolve.
      #
      # @return [ BSON::ObjectId ] The object id.
      #
      # @since 6.0.0
      def evolve(object)
        object.evolve_object_id
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
      # @since 6.0.0
      def mongoize(object)
        object.mongoize_object_id
      end
    end
  end
end