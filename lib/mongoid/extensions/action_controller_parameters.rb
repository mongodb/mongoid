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
        Hash.mongoize(self)
      end
    end
  end
end

if defined?(::ActionController::Parameters)
  ::ActionController::Parameters.__send__(:include, Mongoid::Extensions::ActionControllerParameters)
end
