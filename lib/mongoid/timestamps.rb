module Mongoid
  module Timestamps

    def self.included(base)
      base.class_eval do
        include InstanceMethods
        field :created_at, :type => Time
        field :modified_at, :type => Time
        before_create :update_created_at, :update_modified_at
        before_save :update_modified_at
      end
    end

    module InstanceMethods

      # Update the created_at field on the Document to the current time. This is
      # only called on create.
      def update_created_at
        self.created_at = Time.now.utc
      end

      # Update the last_modified field on the Document to the current time.
      # This is only called on create and on save.
      def update_modified_at
        self.modified_at = Time.now.utc
      end
    end

  end
end
