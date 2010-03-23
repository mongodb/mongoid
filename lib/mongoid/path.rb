# encoding: utf-8
module Mongoid #:nodoc:
  module Path #:nodoc:
    extend ActiveSupport::Concern
    included do
      cattr_accessor :route
      delegate :route, :to => "self.class"
    end
    module InstanceMethods
      # Return the path to this +Document+ in JSON notation, used for atomic
      # updates via $set in MongoDB.
      #
      # Example:
      #
      # <tt>address.path # returns "addresses"</tt>
      def path
        self.route ||= generate
      end

      protected
      # If the path has not been set, then we need to generate it once.
      def generate
        object, json = self, ""
        while (object._parent) do
          json = "#{object.association_name}#{"." + json unless json.blank?}"
          object = object._parent
        end
        json
      end
    end
  end
end
