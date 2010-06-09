# encoding: utf-8
module Mongoid #:nodoc:
  module Timestamps
    extend ActiveSupport::Concern
    included do
      field :created_at, :type => Time
      field :updated_at, :type => Time
      set_callback :create, :before, :set_created_at
      set_callback :save, :before, :set_updated_at
    end

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
