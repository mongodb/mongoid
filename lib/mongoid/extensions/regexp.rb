# encoding: utf-8
module Mongoid
  module Extensions
    module Regexp

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Regexp.mongoize(/^[abc]/)
        #
        # @param [ Regexp, String ] object The object to mongoize.
        #
        # @return [ Regexp ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          ::Regexp.new(object)
        end
      end
    end
  end
end

::Regexp.extend(Mongoid::Extensions::Regexp::ClassMethods)
