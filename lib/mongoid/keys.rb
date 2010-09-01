# encoding: utf-8
module Mongoid #:nodoc:
  module Keys
    extend ActiveSupport::Concern
    included do
      cattr_accessor :primary_key, :_identity
      self._identity = { :type => BSON::ObjectId }

      delegate \
        :_id_type,
        :primary_key,
        :using_object_ids?, :to => "self.class"
    end

    module ClassMethods #:nodoc:

      # Convenience method for returning the type of the id for this class.
      #
      # Example:
      #
      # <tt>Person._id_type</tt>
      #
      # Returns:
      #
      # The type of the id.
      def _id_type
        _identity[:type]
      end

      # Used for telling Mongoid on a per model basis whether to override the
      # default +BSON::ObjectId+ and use a different type. This will be
      # expanded in the future for requiring a PkFactory if the type is not a
      # +BSON::ObjectId+ or +String+.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     identity :type => String
      #   end
      def identity(options = {})
        self._identity = options
      end

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
        identity(:type => String)
        set_callback :save, :before, :identify
      end

      # Convenience method for determining if we are using +BSON::ObjectIds+ as
      # our id.
      #
      # Example:
      #
      # <tt>person.using_object_ids?</tt>
      #
      # Returns:
      #
      # true if we are using BSON::ObjectIds
      def using_object_ids?
        _id_type == BSON::ObjectId
      end
    end
  end
end
