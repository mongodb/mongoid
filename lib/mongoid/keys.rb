# encoding: utf-8
module Mongoid #:nodoc:
  module Keys
    extend ActiveSupport::Concern
    included do
      cattr_accessor :primary_key
      delegate :primary_key, :to => "self.class"
    end

    module ClassMethods #:nodoc:

      # Defines the field that will be used for the id of this +Document+. This
      # set the id of this +Document+ before save to a parameterized version of
      # the field that was supplied. This is good for use for readable URLS in
      # web applications.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     key :first_name, :last_name
      #   end
      def key(*fields)
        self.primary_key = fields
        set_callback :save, :before, :identify
      end
    end
  end
end
