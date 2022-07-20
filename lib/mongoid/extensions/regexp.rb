# frozen_string_literal: true

module Mongoid
  module Extensions
    module Regexp

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Regexp.mongoize(/\A[abc]/)
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Regexp | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.nil?
          case object
          when String then ::Regexp.new(object)
          when ::Regexp then object
          when BSON::Regexp::Raw then object.compile
          end
        rescue RegexpError
          nil
        end
        alias :demongoize :mongoize
      end
    end
  end
end

::Regexp.extend(Mongoid::Extensions::Regexp::ClassMethods)
