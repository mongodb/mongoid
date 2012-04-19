# encoding: utf-8
module Mongoid
  module Extensions
    module String

      attr_accessor :unconvertable_to_bson

      ActiveSupport::Inflector.inflections do |inflect|
        inflect.singular(/address$/, "address")
        inflect.singular("addresses", "address")
        inflect.irregular("canvas", "canvases")
      end

      def __evolve_object_id__
        if BSON::ObjectId.legal?(self)
          BSON::ObjectId.from_string(self)
        else
          blank? ? nil : self
        end
      end

      def __mongoize_time__
        time = Mongoid::Config.use_activesupport_time_zone? ? (::Time.zone || ::Time) : ::Time
        time.parse(self)
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
      # @return [ true, false ] If the string is id or _id.
      #
      # @since 2.3.1
      def mongoid_id?
        self =~ /^(|_)id$/
      end

      # Get the string as a getter string.
      #
      # @example Get the reader/getter
      #   "model=".reader
      #
      # @return [ String ] The string stripped of "=".
      def reader
        delete("=")
      end

      # Convert the string to an array with the string in it.
      #
      # @example Convert the string to an array.
      #   "Testing".to_a
      #
      # @return [ Array ] An array with only the string in it.
      #
      # @since 1.0.0
      def to_a
        [ self ]
      end

      # Is this string a writer?
      #
      # @example Is the string a setter method?
      #   "model=".writer?
      #
      # @return [ true, false ] If the string contains "=".
      def writer?
        include?("=")
      end

      # Is the object not to be converted to bson on criteria creation?
      #
      # @example Is the object unconvertable?
      #   object.unconvertable_to_bson?
      #
      # @return [ true, false ] If the object is unconvertable.
      #
      # @since 2.2.1
      def unconvertable_to_bson?
        @unconvertable_to_bson ||= false
      end

      module ClassMethods

        # Convert the object from it's mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   String.demongoize(object)
        #
        # @param [ Object ] object The object to demongoize.
        #
        # @return [ String ] The object.
        #
        # @since 3.0.0
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
        # @since 3.0.0
        def mongoize(object)
          demongoize(object)
        end
      end
    end
  end
end

::String.__send__(:include, Mongoid::Extensions::String)
::String.__send__(:extend, Mongoid::Extensions::String::ClassMethods)
