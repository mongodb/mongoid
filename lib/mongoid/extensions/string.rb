# frozen_string_literal: true

module Mongoid
  module Extensions
    module String

      # @attribute [rw] unconvertable_to_bson If the document is unconvertable.
      attr_accessor :unconvertable_to_bson

      # Evolve the string into an object id if possible.
      #
      # @example Evolve the string.
      #   "test".__evolve_object_id__
      #
      # @return [ String | BSON::ObjectId ] The evolved string.
      def __evolve_object_id__
        convert_to_object_id
      end

      # Mongoize the string into an object id if possible.
      #
      # @example Evolve the string.
      #   "test".__mongoize_object_id__
      #
      # @return [ String | BSON::ObjectId | nil ] The mongoized string.
      def __mongoize_object_id__
        convert_to_object_id unless blank?
      end

      # Mongoize the string for storage.
      #
      # @note Returns a local time in the default time zone.
      #
      # @example Mongoize the string.
      #   "2012-01-01".__mongoize_time__
      #   # => 2012-01-01 00:00:00 -0500
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] Local time in the
      #   configured default time zone corresponding to this string.
      def __mongoize_time__
        # This extra parse from Time is because ActiveSupport::TimeZone
        # either returns nil or Time.now if the string is empty or invalid,
        # which is a regression from pre-3.0 and also does not agree with
        # the core Time API.
        parsed = ::Time.parse(self)
        if ::Time == ::Time.configured
          parsed
        else
          ::Time.configured.parse(self)
        end
      end

      # Convert the string to a collection friendly name.
      #
      # @example Collectionize the string.
      #   "namespace/model".collectionize
      #
      # @return [ String ] The string in collection friendly form.
      def collectionize
        tableize.gsub("/", "_")
      end

      # Is the string a valid value for a Mongoid id?
      #
      # @example Is the string an id value?
      #   "_id".mongoid_id?
      #
      # @return [ true | false ] If the string is id or _id.
      def mongoid_id?
        self =~ /\A(|_)id\z/
      end

      # Is the string a number? The literals "NaN", "Infinity", and "-Infinity"
      # are counted as numbers.
      #
      # @example Is the string a number.
      #   "1234.23".numeric?
      #
      # @return [ true | false ] If the string is a number.
      def numeric?
        !!Float(self)
      rescue ArgumentError
        (self =~ /\A(?:NaN|-?Infinity)\z/) == 0
      end

      # Get the string as a getter string.
      #
      # @example Get the reader/getter
      #   "model=".reader
      #
      # @return [ String ] The string stripped of "=".
      def reader
        delete("=").sub(/\_before\_type\_cast\z/, '')
      end

      # Is this string a writer?
      #
      # @example Is the string a setter method?
      #   "model=".writer?
      #
      # @return [ true | false ] If the string contains "=".
      def writer?
        include?("=")
      end

      # Is this string a valid_method_name?
      #
      # @example Is the string a valid Ruby identifier for use as a method name
      #   "model=".valid_method_name?
      #
      # @return [ true | false ] If the string contains a valid Ruby identifier.
      def valid_method_name?
        /[@$"-]/ !~ self
      end

      # Does the string end with _before_type_cast?
      #
      # @example Is the string a setter method?
      #   "price_before_type_cast".before_type_cast?
      #
      # @return [ true | false ] If the string ends with "_before_type_cast"
      def before_type_cast?
        ends_with?("_before_type_cast")
      end

      # Is the object not to be converted to bson on criteria creation?
      #
      # @example Is the object unconvertable?
      #   object.unconvertable_to_bson?
      #
      # @return [ true | false ] If the object is unconvertable.
      def unconvertable_to_bson?
        @unconvertable_to_bson ||= false
      end

      private

      # If the string is a legal object id, convert it.
      #
      # @api private
      #
      # @example Convert to the object id.
      #   string.convert_to_object_id
      #
      # @return [ String | BSON::ObjectId ] The string or the id.
      def convert_to_object_id
        BSON::ObjectId.legal?(self) ? BSON::ObjectId.from_string(self) : self
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   String.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        def mongoize(object)
          object.try(:to_s)
        end
        alias :demongoize :mongoize
      end
    end
  end
end

::String.__send__(:include, Mongoid::Extensions::String)
::String.extend(Mongoid::Extensions::String::ClassMethods)
