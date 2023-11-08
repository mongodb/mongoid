# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Extensions

    # Adds type-casting behavior to Hash class.
    module Hash

      # Evolves each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.__evolve_object_id__
      #
      # @return [ Hash ] The converted hash.
      def __evolve_object_id__
        transform_values!(&:__evolve_object_id__)
      end

      # Mongoizes each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.__mongoize_object_id__
      #
      # @return [ Hash ] The converted hash.
      def __mongoize_object_id__
        if id = self['$oid']
          BSON::ObjectId.from_string(id)
        else
          transform_values!(&:__mongoize_object_id__)
        end
      end

      # Consolidate the key/values in the hash under an atomic $set.
      # DEPRECATED. This was never intended to be a public API and
      # the functionality will no longer be exposed once this method
      # is eventually removed.
      #
      # @example Consolidate the hash.
      #   { name: "Placebo" }.__consolidate__
      #
      # @return [ Hash ] A new consolidated hash.
      #
      # @deprecated
      def __consolidate__(klass)
        Mongoid::AtomicUpdatePreparer.prepare(self, klass)
      end
      Mongoid.deprecate(self, :__consolidate__)

      # Deletes an id value from the hash.
      #
      # @example Delete an id value.
      #   {}.delete_id
      #
      # @return [ Object ] The deleted value, or nil.
      # @deprecated
      def delete_id
        delete("_id") || delete(:_id) || delete("id") || delete(:id)
      end
      Mongoid.deprecate(self, :delete_id)

      # Get the id attribute from this hash, whether it's prefixed with an
      # underscore or is a symbol.
      #
      # @example Extract the id.
      #   { :_id => 1 }.extract_id
      #
      # @return [ Object ] The value of the id.
      # @deprecated
      def extract_id
        self["_id"] || self[:_id] || self["id"] || self[:id]
      end
      Mongoid.deprecate(self, :extract_id)

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Hash | nil ] The object mongoized or nil.
      def mongoize
        ::Hash.mongoize(self)
      end

      # Can the size of this object change?
      #
      # @example Is the hash resizable?
      #   {}.resizable?
      #
      # @return [ true ] true.
      def resizable?
        true
      end

      # Convert this hash to a criteria. Will iterate over each keys in the
      # hash which must correspond to method on a criteria object. The hash
      # must also include a "klass" key.
      #
      # @example Convert the hash to a criteria.
      #   { klass: Band, where: { name: "Depeche Mode" }.to_criteria
      #
      # @return [ Criteria ] The criteria.
      # @deprecated
      def to_criteria
        Criteria.from_hash(self)
      end
      Mongoid.deprecate(self, :to_criteria)

      private

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Hash.mongoize([ 1, 2, 3 ])
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Hash | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?
          case object
          when BSON::Document
            object.dup.transform_values!(&:mongoize)
          when Hash
            BSON::Document.new(object.transform_values(&:mongoize))
          end
        end

        # Can the size of this object change?
        #
        # @example Is the hash resizable?
        #   {}.resizable?
        #
        # @return [ true ] true.
        def resizable?
          true
        end
      end
    end
  end
end

::Hash.__send__(:include, Mongoid::Extensions::Hash)
::Hash.extend(Mongoid::Extensions::Hash::ClassMethods)
