# encoding: utf-8
module Mongoid #:nodoc:

  # This module handles the behaviour for setting up document created at and
  # updated at timestamps.
  module Timestamps
    extend ActiveSupport::Concern

    included do
      field :created_at, :type => Time
      field :updated_at, :type => Time

      set_callback :create, :before, :set_created_at
      set_callback :save, :before, :set_updated_at, :if => Proc.new {|d| d.new_record? || d.changed? }

      class_attribute :record_timestamps
      self.record_timestamps = true
    end

    # Update the created_at field on the Document to the current time. This is
    # only called on create.
    #
    # @example Set the created at time.
    #   person.set_created_at
    def set_created_at
      self.created_at = Time.now.utc if !created_at
    end

    # Update the updated_at field on the Document to the current time.
    # This is only called on create and on save.
    #
    # @example Set the updated at time.
    #   person.set_updated_at
    def set_updated_at
      self.updated_at = Time.now.utc
    end
  end
end
