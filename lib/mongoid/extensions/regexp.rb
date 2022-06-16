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
        # @param [ Regexp, String ] object The object to mongoize.
        #
        # @return [ Regexp ] The object mongoized.
        def mongoize(object)
          return if object.nil?
          case object
          when String, ::Regexp then ::Regexp.new(object)
          else raise Errors::InvalidValue.new(self, object)
          end
        end
      end
    end
  end
end

::Regexp.extend(Mongoid::Extensions::Regexp::ClassMethods)
