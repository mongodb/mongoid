# encoding: utf-8
module Mongoid
  module Timestamps

    def self.included(base)
      base.class_eval do
        include InstanceMethods
        field :created_at, :type => Time
        field :updated_at, :type => Time
        before_save :set_created_at, :set_updated_at
      end
    end

    module InstanceMethods

      # Update the created_at field on the Document to the current time. This is
      # only called on create.
      def set_created_at
        self.created_at = Time.now.utc if !created_at
      end

      # Update the updated_at field on the Document to the current time.
      # This is only called on create and on save.
      def set_updated_at
        self.updated_at = Time.now.utc
      end
    end

  end
end
