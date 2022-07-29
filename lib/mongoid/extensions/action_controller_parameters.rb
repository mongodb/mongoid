# frozen_string_literal: true

module Mongoid
  module Extensions
    module ActionControllerParameters

      # Turn the object from the Ruby type into a Mongo-friendly type.
      #
      # @example Mongoize the object.
      #   object.mongoize
      #
      # @return [ Object ] The object.
      def mongoize
        ::Hash.mongoize(self)
      end

      module ClassMethods

        # Turn the object from the Ruby type into a Mongo-friendly type.
        #
        # @example Mongoize the object.
        #   ActionController::Parameters.mongoize([ 1, 2, 3 ])
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ Hash ] The object mongoized.
        def mongoize(object)
          ::Hash.mongoize(object)
        end
      end
    end
  end
end

if defined?(::ActionController::Parameters)
  ::ActionController::Parameters.__send__(:include, Mongoid::Extensions::ActionControllerParameters)
  ::ActionController::Parameters.extend(Mongoid::Extensions::ActionControllerParameters::ClassMethods)
end
