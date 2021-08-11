# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Extensions
    module Range

      # Get the range as arguments for a find.
      #
      # @example Get the range as find args.
      #   range.__find_args__
      #
      # @return [ Array ] The range as an array.
      #
      # @since 3.0.0
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
      #
      # @since 3.0.0
      def mongoize
        ::Range.mongoize(self)
      end

      # Is this a resizable object.
      #
      # @example Is this resizable?
      #   range.resizable?
      #
      # @return [ true ] True.
      #
      # @since 3.0.0
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
        # @return [ Range, Hash ] The range, or database hash object if cannot be represented as range.
        #
        # @since 3.0.0
        def demongoize(object)
          object.nil? ? nil : ::Range.new(object["min"], object["max"], object["exclude_end"])
        rescue ArgumentError # can be removed when Ruby version >= 2.7
          object
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
        #
        # @since 3.0.0
        def mongoize(object)
          case object
          when NilClass then nil
          when String then object
          when Hash then __mongoize_hash__(object)
          else __mongoize_range__(object)
          end
        end

        private

        def __mongoize_hash__(object)
          hash = object.stringify_keys
          hash.slice!('min', 'max', 'exclude_end')
          hash.compact!
          hash.transform_values!(&:mongoize)
          hash
        end

        def __mongoize_range__(object)
          hash = {}
          hash['min'] = object.begin.mongoize if object.begin
          hash['max'] = object.end.mongoize if object.end
          if object.respond_to?(:exclude_end?) && object.exclude_end?
            hash['exclude_end'] = true
          end
          hash
        end
      end
    end
  end
end

::Range.__send__(:include, Mongoid::Extensions::Range)
::Range.extend(Mongoid::Extensions::Range::ClassMethods)
