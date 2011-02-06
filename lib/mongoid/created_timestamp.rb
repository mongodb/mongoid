# encoding: utf-8
module Mongoid #:nodoc:

  # This module handles the behaviour for setting up document created at
  # timestamp.
  module CreatedTimestamp
    extend ActiveSupport::Concern

    included do
      field :created_at, :type => Time

      set_callback :create, :before, :set_created_at
    end

    # Update the created_at field on the Document to the current time. This is
    # only called on create.
    #
    # @example Set the created at time.
    #   person.set_created_at
    def set_created_at
      self.created_at = Time.now.utc if !created_at
    end
  end
end
