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
      # @return [ Hash | nil ] The object mongoized or nil.
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
        # @return [ Range | nil ] The range, or nil if object cannot be represented as range.
        #
        # @note Ruby 2.6 and lower do not support endless ranges that Ruby 2.7+ support.
        def demongoize(object)
          return if object.nil?
          if object.is_a?(Hash)
            hash = object.slice('min', 'max', 'exclude_end', :min, :max, :exclude_end)
            unless hash.blank?
              begin
                ::Range.new(hash["min"] || hash[:min],
                            hash["max"] || hash[:max],
                            hash["exclude_end"] || hash[:exclude_end])
              rescue ArgumentError # can be removed when Ruby version >= 2.7
                nil
              end
            end
          end
        end

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Range.mongoize(1..3)
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Hash | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?
          case object
          when Hash then __mongoize_hash__(object)
          when Range then __mongoize_range__(object)
          end
        end

        private

        def __mongoize_hash__(object)
          hash = object.stringify_keys
          hash.slice!('min', 'max', 'exclude_end')
          hash.compact!
          hash.transform_values!(&:mongoize)
          hash.blank? ? nil : hash
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
