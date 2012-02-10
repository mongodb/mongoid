# encoding: utf-8
module Mongoid #:nodoc:
  module Timestamps
    # This module handles the behaviour for setting up document updated at
    # timestamp.
    module Updated
      extend ActiveSupport::Concern

      included do
        field :updated_at, :type => Time
        set_callback :save, :before, :set_updated_at, :if => :able_to_set_updated_at?
      end

      # Update the updated_at field on the Document to the current time.
      # This is only called on create and on save.
      #
      # @example Set the updated at time.
      #   person.set_updated_at
      def set_updated_at
        self.updated_at = Time.now.utc unless updated_at_changed?
      end

      # Is the updated timestamp able to be set?
      #
      # @example Can the timestamp be set?
      #   document.able_to_set_updated_at?
      #
      # @return [ true, false ] If the timestamp can be set.
      #
      # @since 2.4.0
      def able_to_set_updated_at?
        !frozen? && timestamping? && (new_record? || changed?)
      end
    end
  end
end
