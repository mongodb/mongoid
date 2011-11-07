# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module ObjectId #:nodoc:

      # Provides conversions to and from BSON::ObjectIds and Strings, Arrays,
      # and Hashes.
      module Conversions

        # Convert the supplied arguments to object ids based on the class
        # settings.
        #
        # @todo Durran: This method can be refactored.
        #
        # @example Convert a string to an object id
        #   BSON::ObjectId.convert(Person, "4c52c439931a90ab29000003")
        #
        # @example Convert an array of strings to object ids.
        #   BSON::ObjectId.convert(Person, [ "4c52c439931a90ab29000003" ])
        #
        # @example Convert a hash of id strings to object ids.
        #   BSON::ObjectId.convert(Person, { :_id => "4c52c439931a90ab29000003" })
        #
        # @param [ Class ] klass The class to convert the ids for.
        # @param [ Object, Array, Hash ] object The object to convert.
        #
        # @raise BSON::InvalidObjectId If using object ids and passed bad
        #   strings.
        #
        # @return [ BSON::ObjectId, Array, Hash ] The converted object ids.
        #
        # @since 2.0.0.rc.7
        def convert(klass, object, reject_blank = true)
          return object if object.is_a?(BSON::ObjectId) || !klass.using_object_ids?
          case object
          when ::String
            return nil if object.blank?
            if object.unconvertable_to_bson?
              object
            else
              BSON::ObjectId.legal?(object) ? BSON::ObjectId.from_string(object) : object
            end
          when ::Array
            object.delete_if { |arg| arg.blank? } if reject_blank
            object.replace(object.map { |arg| convert(klass, arg, reject_blank) })
          when ::Hash
            object.tap do |hash|
              hash.each_pair do |key, value|
                next unless klass.object_id_field?(key)
                hash[key] = convert(klass, value, reject_blank)
              end
            end
          else
            object
          end
        end
      end
    end
  end
end
