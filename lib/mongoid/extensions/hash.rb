# frozen_string_literal: true

module Mongoid
  module Extensions
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
      #
      # @example Consolidate the hash.
      #   { name: "Placebo" }.__consolidate__
      #
      # @return [ Hash ] A new consolidated hash.
      def __consolidate__(klass)
        consolidated = {}
        each_pair do |key, value|
          if key =~ /\$/
            value.each_pair do |_key, _value|
              value[_key] = (key == "$rename") ? _value.to_s : mongoize_for(key, klass, _key, _value)
            end
            consolidated[key] ||= {}
            consolidated[key].update(value)
          else
            consolidated["$set"] ||= {}
            consolidated["$set"].update(key => mongoize_for(key, klass, key, value))
          end
        end
        consolidated
      end

      # Checks whether conditions given in this hash are known to be
      # unsatisfiable, i.e., querying with this hash will always return no
      # documents.
      #
      # This method only handles condition shapes that Mongoid itself uses when
      # it builds association queries. It does not guarantee that a false
      # return value means the condition can produce a non-empty document set -
      # only that if the return value is true, the condition always produces
      # an empty document set.
      #
      # @example Unsatisfiable conditions
      #   {'_id' => {'$in' => []}}._mongoid_unsatisfiable_criteria?
      #   # => true
      #
      # @example Conditions which could be satisfiable
      #   {'_id' => '123'}._mongoid_unsatisfiable_criteria?
      #   # => false
      #
      # @example Conditions which are unsatisfiable that this method does not handle
      #   {'foo' => {'$in' => []}}._mongoid_unsatisfiable_criteria?
      #   # => false
      #
      # @return [ true | false ] Whether hash contains known unsatisfiable
      #   conditions.
      # @api private
      def _mongoid_unsatisfiable_criteria?
        unsatisfiable_criteria = { "_id" => { "$in" => [] }}
        return true if self == unsatisfiable_criteria
        return false unless length == 1 && keys == %w($and)
        value = values.first
        value.is_a?(Array) && value.any? do |sub_v|
          sub_v.is_a?(Hash) && sub_v._mongoid_unsatisfiable_criteria?
        end
      end

      # Checks whether conditions given in this hash are known to be
      # unsatisfiable, i.e., querying with this hash will always return no
      # documents.
      #
      # This method is deprecated. Mongoid now uses
      # +_mongoid_unsatisfiable_criteria?+ internally; this method is retained
      # for backwards compatibility only.
      #
      # @return [ true | false ] Whether hash contains known unsatisfiable
      #   conditions.
      # @deprecated
      alias :blank_criteria? :_mongoid_unsatisfiable_criteria?

      # Deletes an id value from the hash.
      #
      # @example Delete an id value.
      #   {}.delete_id
      #
      # @return [ Object ] The deleted value, or nil.
      def delete_id
        delete("_id") || delete(:_id) || delete("id") || delete(:id)
      end

      # Get the id attribute from this hash, whether it's prefixed with an
      # underscore or is a symbol.
      #
      # @example Extract the id.
      #   { :_id => 1 }.extract_id
      #
      # @return [ Object ] The value of the id.
      def extract_id
        self["_id"] || self[:_id] || self["id"] || self[:id]
      end

      # Fetch a nested value via dot syntax.
      #
      # @example Fetch a nested value via dot syntax.
      #   { "name" => { "en" => "test" }}.__nested__("name.en")
      #
      # @param [ String ] string the dot syntax string.
      #
      # @return [ Object ] The matching value.
      def __nested__(string)
        keys = string.split(".")
        value = self
        keys.each do |key|
          return nil if value.nil?
          value_for_key = value[key]
          if value_for_key.nil? && key.to_i.to_s == key
            value_for_key = value[key.to_i]
          end
          value = value_for_key
        end
        value
      end

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
      def to_criteria
        criteria = Criteria.new(delete(:klass) || delete("klass"))
        each_pair do |method, args|
          criteria = criteria.__send__(method, args)
        end
        criteria
      end

      private

      # Mongoize for the klass, key and value.
      #
      # @api private
      #
      # @example Mongoize for the klass, field and value.
      #   {}.mongoize_for("$push", Band, "name", "test")
      #
      # @param [ String ] operator The operator.
      # @param [ Class ] klass The model class.
      # @param [ String | Symbol ] key The field key.
      # @param [ Object ] value The value to mongoize.
      #
      # @return [ Object ] The mongoized value.
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
          if object.is_a?(Hash)
            # Need to use transform_values! which maintains the BSON::Document
            # instead of transform_values which always returns a hash. To do this,
            # we first need to dup the hash.
            object.dup.transform_values!(&:mongoize)
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

::Mongoid.deprecate(Hash, :blank_criteria)
