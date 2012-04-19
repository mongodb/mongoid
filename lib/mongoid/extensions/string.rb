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

      REVERSALS = {
        "asc" => "desc",
        "ascending" => "descending",
        "desc" => "asc",
        "descending" => "ascending"
      }

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

      # Get the inverted sorting option.
      #
      # @example Get the inverted option.
      #   "asc".invert
      #
      # @return [ String ] The string inverted.
      def invert
        REVERSALS[self]
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
    end
  end
end

::String.__send__(:include, Mongoid::Extensions::String)
