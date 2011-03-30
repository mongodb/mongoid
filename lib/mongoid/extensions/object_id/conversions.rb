# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module ObjectId #:nodoc:

      # Provides conversions to and from BSON::ObjectIds and Strings, Arrays,
      # and Hashes.
      module Conversions

        # Set the BSON::ObjectId value.
        #
        # @example Set the value.
        #   BSON::ObjectId.set("4c52c439931a90ab29000003")
        #
        # @param [ String, BSON::ObjectId ] value The value to set.
        #
        # @return [ BSON::ObjectId ] The set value.
        #
        # @since 1.0
        def set(value)
          if value.is_a?(::String)
            BSON::ObjectId.from_string(value) unless value.blank?
          else
            value
          end
        end

        # Get the BSON::ObjectId value.
        #
        # @example Get the value.
        #   BSON::ObjectId.set(BSON::ObjectId.new)
        #
        # @param [ BSON::ObjectId ] value The value to get.
        #
        # @return [ BSON::ObjectId ] The value.
        #
        # @since 1.0
        def get(value)
          value
        end

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
        # @param [ Object, Array, Hash ] args The object to convert.
        #
        # @raise BSON::InvalidObjectId If using object ids and passed bad
        #   strings.
        #
        # @return [ BSON::ObjectId, Array, Hash ] The converted object ids.
        #
        # @since 2.0.0.rc.7
        def convert(klass, args, reject_blank = true)
          return args if args.is_a?(BSON::ObjectId) || !klass.using_object_ids?
          case args
          when ::String
            args.blank? ? nil : BSON::ObjectId.from_string(args)
          when ::Array
            args = args.reject(&:blank?) if reject_blank
            args.map do |arg|
              convert(klass, arg, reject_blank)
            end
          when ::Hash
            args.tap do |hash|
              hash.each_pair do |key, value|
                next unless key.to_s =~ /id/
                begin
                  hash[key] = convert(klass, value, reject_blank)
                rescue BSON::InvalidObjectId; end
              end
            end
          else
            args
          end
        end
      end
    end
  end
end
