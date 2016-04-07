module Mongoid
  module Refinements

    refine String do

      # @attribute [rw] unconvertable_to_bson If the document is unconvetable.
      attr_accessor :unconvertable_to_bson

      # Does the string end with _before_type_cast?
      #
      # @example Is the string a setter method?
      #   "price_before_type_cast".before_type_cast?
      #
      # @return [ true, false ] If the string ends with "_before_type_cast"
      #
      # @since 6.0.0
      def before_type_cast?
        ends_with?("_before_type_cast")
      end

      # Convert the string to a collection friendly name.
      #
      # @example Collectionize the string.
      #   "namespace/model".collectionize
      #
      # @return [ String ] The string in collection friendly form.
      #
      # @since 6.0.0
      def collectionize
        tableize.gsub("/", "_")
      end

      # If the string is a legal object id, convert it.
      #
      # @example Convert to the object id.
      #   string.convert_to_object_id
      #
      # @return [ String, BSON::ObjectId ] The string or the id.
      #
      # @since 6.0.0
      def convert_to_object_id
        BSON::ObjectId.legal?(self) ? BSON::ObjectId.from_string(self) : self
      end

      # Evolve the string into an object id if possible.
      #
      # @example Evolve the string.
      #   "test".evolve_object_id
      #
      # @return [ String, BSON::ObjectId ] The evolved string.
      #
      # @since 6.0.0
      def evolve_object_id
        convert_to_object_id
      end

      # Mongoize the string into an object id if possible.
      #
      # @example Evolve the string.
      #   "test".mongoize_object_id
      #
      # @return [ String, BSON::ObjectId, nil ] The mongoized string.
      #
      # @since 6.0.0
      def mongoize_object_id
        convert_to_object_id unless blank?
      end

      # Mongoize the string for storage.
      #
      # @example Mongoize the string.
      #   "2012-01-01".mongoize_time
      #
      # @note The extra parse from Time is because ActiveSupport::TimeZone
      #   either returns nil or Time.now if the string is empty or invalid,
      #   which is a regression from pre-3.0 and also does not agree with
      #   the core Time API.
      #
      # @return [ Time ] The time.
      #
      # @since 6.0.0
      def mongoize_time
        ::Time.parse(self)
        ::Time.configured.parse(self)
      end

      # Is the string a number?
      #
      # @example Is the string a number.
      #   "1234.23".numeric?
      #
      # @return [ true, false ] If the string is a number.
      #
      # @since 6.0.0
      def numeric?
        true if Float(self) rescue (self == "NaN")
      end

      # Get the string as a getter string.
      #
      # @example Get the reader/getter
      #   "model=".reader
      #
      # @return [ String ] The string stripped of "=".
      #
      # @since 6.0.0
      def reader
        delete("=").sub(/\_before\_type\_cast$/, '')
      end

      # Is the object not to be converted to bson on criteria creation?
      #
      # @example Is the object unconvertable?
      #   object.unconvertable_to_bson?
      #
      # @return [ true, false ] If the object is unconvertable.
      #
      # @since 6.0.0
      def unconvertable_to_bson?
        @unconvertable_to_bson ||= false
      end

      # Is this string a valid_method_name?
      #
      # @example Is the string a valid Ruby idenfier for use as a method name
      #   "model=".valid_method_name?
      #
      # @return [ true, false ] If the string contains a valid Ruby identifier.
      #
      # @since 6.0.0
      def valid_method_name?
        /[@$"-]/ !~ self
      end

      # Is this string a writer?
      #
      # @example Is the string a setter method?
      #   "model=".writer?
      #
      # @return [ true, false ] If the string contains "=".
      #
      # @since 6.0.0
      def writer?
        include?("=")
      end
    end

    refine String.singleton_class do

      # Convert the object from its mongo friendly ruby type to this type.
      #
      # @example Demongoize the object.
      #   String.demongoize(object)
      #
      # @param [ Object ] object The object to demongoize.
      #
      # @return [ String ] The object.
      #
      # @since 6.0.0
      def demongoize(object)
        object.try(:to_s)
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   String.mongoize("123.11")
      #
      # @param [ Object ] object The object to mongoize.
      #
      # @return [ String ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        demongoize(object)
      end
    end
  end
end