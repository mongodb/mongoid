# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module ObjectId

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
      # @param [ Boolean ] reject_blank delete blank element from object received like args
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
          convert_from_string(klass, object)
        when ::Array
          convert_from_array(klass, object, reject_blank)
        when ::Hash
          convert_from_hash(klass, object, reject_blank)
        else
          object
        end
      end

      # Convert the supplied string ids based on the class
      # settings.
      #
      # @example Convert a string to an object id
      #   BSON::ObjectId.convert(Person, "4c52c439931a90ab29000003")
      #
      # @param [ Class ] klass The class to convert the ids for.
      # @param [ String ] object The string to convert.
      #
      # @raise BSON::InvalidObjectId If using object ids and passed bad
      #   strings.
      #
      # @return [ BSON::ObjectId ] The converted object ids.
      #
      # @since 3.0.0
      def convert_from_string(klass, object)
        return nil if object.blank?
        if object.unconvertable_to_bson? || !BSON::ObjectId.legal?(object)
          object
        else
          BSON::ObjectId.from_string(object)
        end
      end

      # Convert the supplied arguments to array ids based on the class
      # settings.
      #
      # @example Convert an array of strings to object ids.
      #   BSON::ObjectId.convert(Person, [ "4c52c439931a90ab29000003" ])
      #
      # @param [ Class ] klass The class to convert the ids for.
      # @param [ Array ] object The array to convert.
      # @param [ Boolean ] reject_blank delete blank element from array received like args
      #
      # @raise BSON::InvalidObjectId If using object ids and passed bad
      #   strings.
      #
      # @return [ Array ] The converted object ids.
      #
      # @since 3.0.0
      def convert_from_array(klass, object, reject_blank=true)
        object.delete_if { |arg| arg.blank? } if reject_blank
        object.replace(object.map { |arg| convert(klass, arg, reject_blank) })
      end

      # Convert the supplied arguments to hash ids based on the class
      # settings.
      #
      # @example Convert a hash of id strings to object ids.
      #   BSON::ObjectId.convert(Person, { :_id => "4c52c439931a90ab29000003" })
      #
      # @param [ Class ] klass The class to convert the ids for.
      # @param [ Hash ] object The hash to convert.
      # @param [ Boolean ] reject_blank delete blank element from hash received like args
      #
      # @raise BSON::InvalidObjectId If using object ids and passed bad
      #   strings.
      #
      # @return [ Hash ] The converted object ids.
      #
      # @since 3.0.0
      def convert_from_hash(klass, object, reject_blank=true)
        object.each_pair do |key, value|
          next unless klass.object_id_field?(key)
          object[key] = convert(klass, value, reject_blank)
        end
        object
      end

      def evolve(object)
        __evolve__(object) do |obj|
          if obj.is_a?(BSON::ObjectId) || !BSON::ObjectId.legal?(obj)
            obj
          else
            BSON::ObjectId.from_string(obj)
          end
        end
      end
    end
  end
end

::BSON::ObjectId.__send__(:extend, Mongoid::Extensions::ObjectId)
