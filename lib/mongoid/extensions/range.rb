# frozen_string_literal: true

module Mongoid
  module Extensions
    module Range

      # Get the range as arguments for a find.
      #
      # @example Get the range as find args.
      #   range.__find_args__
      #
      # @return [ Array ] The range as an array.
      def __find_args__
        to_a
      end

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   range.mongoize
      #
      # @return [ Hash ] The object mongoized.
      def mongoize
        ::Range.mongoize(self)
      end

      # Is this a resizable object.
      #
      # @example Is this resizable?
      #   range.resizable?
      #
      # @return [ true ] True.
      def resizable?
        true
      end

      module ClassMethods

        # Convert the object from its mongo friendly ruby type to this type.
        #
        # @example Demongoize the object.
        #   Range.demongoize({ "min" => 1, "max" => 5 })
        #
        # @param [ Hash ] object The object to demongoize.
        #
        # @return [ Range ] The range.
        def demongoize(object)
          object.nil? ? nil : ::Range.new(object["min"], object["max"], object["exclude_end"])
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Range.mongoize(1..3)
        #
        # @param [ Range ] object The object to mongoize.
        #
        # @return [ Hash ] The object mongoized.
        def mongoize(object)
          return nil if object.nil?
          return object if object.is_a?(::Hash)
          return object if object.is_a?(String)
          hash = { "min" => object.first, "max" => object.last }
          if object.respond_to?(:exclude_end?) && object.exclude_end?
            hash.merge!("exclude_end" => true)
          end
          hash
        end
      end
    end
  end
end

::Range.__send__(:include, Mongoid::Extensions::Range)
::Range.extend(Mongoid::Extensions::Range::ClassMethods)
