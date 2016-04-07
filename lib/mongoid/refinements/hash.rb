module Mongoid
  module Refinements

    # The object id extended JSON constant.
    #
    # @since 6.0.0
    OID = '$oid'.freeze

    refine Hash do

      # Check if the hash is part of a blank relation criteria.
      #
      # @example Is the hash blank criteria?
      #   {}.blank_criteria?
      #
      # @return [ true, false ] If the hash is blank criteria.
      #
      # @since 6.0.0
      def blank_criteria?
        self == { "_id" => { "$in" => [] }}
      end

      # Consolidate the key/values in the hash under an atomic $set.
      #
      # @example Consolidate the hash.
      #   { name: "Placebo" }.consolidate
      #
      # @return [ Hash ] A new consolidated hash.
      #
      # @since 6.0.0
      def consolidate(klass)
        consolidated = {}
        each_pair do |key, value|
          if key =~ /\$/
            value.each_pair do |_key, _value|
              value[_key] = (key == "$rename") ? _value.to_s : mongoize_for(key, klass, _key, _value)
            end
            (consolidated[key] ||= {}).merge!(value)
          else
            (consolidated["$set"] ||= {}).merge!(key => mongoize_for(key, klass, key, value))
          end
        end
        consolidated
      end

      # Deletes an id value from the hash.
      #
      # @example Delete an id value.
      #   {}.delete_id
      #
      # @return [ Object ] The deleted value, or nil.
      #
      # @since 6.0.0
      def delete_id
        delete("_id") || delete("id") || delete(:id) || delete(:_id)
      end

      # Evolves each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.evolve_object_id
      #
      # @return [ Hash<String, BSON::ObjectId> ] The converted hash.
      #
      # @since 6.0.0
      def evolve_object_id
        update_values{ |v| v.evolve_object_id }
      end

      # Get the id attribute from this hash, whether it's prefixed with an
      # underscore or is a symbol.
      #
      # @example Extract the id.
      #   { :_id => 1 }.extract_id
      #
      # @return [ Object ] The value of the id.
      #
      # @since 6.0.0
      def extract_id
        self["_id"] || self["id"] || self[:id] || self[:_id]
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Hash ] The object.
      #
      # @since 6.0.0
      def mongoize
        ::Hash.mongoize(self)
      end

      # Mongoize for the klass, key and value.
      #
      # @example Mongoize for the klass, field and value.
      #   {}.mongoize_for(Band, "name", "test")
      #
      # @param [ Class ] klass The model class.
      # @param [ String, Symbol ] The field key.
      # @param [ Object ] value The value to mongoize.
      #
      # @return [ Object ] The mongoized value.
      #
      # @since 3.1.0
      def mongoize_for(operator, klass, key, value)
        field = klass.fields[key.to_s]
        if field
          val = field.mongoize(value)
          if Mongoid::Persistable::LIST_OPERATIONS.include?(operator) && field.resizable?
            val = val.first if !value.is_a?(Array)
          end
          val
        else
          value
        end
      end

      # Mongoizes each value in the hash to an object id if it is convertable.
      #
      # @example Convert the hash values.
      #   { field: id }.mongoize_object_id
      #
      # @return [ Hash ] The converted hash.
      #
      # @since 6.0.0
      def mongoize_object_id
        if id = self[OID]
          BSON::ObjectId.from_string(id)
        else
          update_values{ |v| v.mongoize_object_id }
        end
      end

      # Fetch a nested value via dot syntax.
      #
      # @example Fetch a nested value via dot syntax.
      #   { "name" => { "en" => "test" }}.nested_value("name.en")
      #
      # @param [ String ] string the dot syntax string.
      #
      # @return [ Object ] The matching value.
      #
      # @since 3.0.15
      def nested_value(string)
        keys = string.split(".")
        value = self
        keys.each do |key|
          nested = value[key] || value[key.to_i]
          value = nested
        end
        value
      end

      # Can the size of this object change?
      #
      # @example Is the hash resizable?
      #   {}.resizable?
      #
      # @return [ true ] true.
      #
      # @since 6.0.0
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
      #
      # @since 3.0.7
      def to_criteria
        criteria = Criteria.new(delete(:klass) || delete("klass"))
        each_pair do |method, args|
          criteria = criteria.__send__(method, args)
        end
        criteria
      end
    end

    refine Hash.singleton_class do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Hash.mongoize([ 1, 2, 3 ])
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ Hash ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        return if object.nil?
        evolve(object.dup).update_values { |value| value.mongoize }
      end

      # Can the size of this object change?
      #
      # @example Is the hash resizable?
      #   Hash.resizable?
      #
      # @return [ true ] true.
      #
      # @since 6.0.0
      def resizable?
        true
      end
    end
  end
end