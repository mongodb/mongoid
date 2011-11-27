# encoding: utf-8
module Mongoid #:nodoc:
  module Timestamps
    # This module handles the behaviour for setting up document updated at
    # timestamp.
    module Updated
      extend ActiveSupport::Concern

      included do
        field :updated_at, :type => Time, :versioned => false
        set_callback :save, :before, :set_updated_at, :if => Proc.new { |doc|
          doc.timestamping? && (doc.new_record? || doc.changed?)
        }
      end

      # Update the updated_at field on the Document to the current time.
      # This is only called on create and on save.
      #
      # @example Set the updated at time.
      #   person.set_updated_at
      def set_updated_at
        self.updated_at = Time.now.utc unless updated_at_changed?
      end

      # Print out the cache key.
      # Will append different values on the plural model name
      # If new_record?     - will append /new
      # If not             - will append /id-updated_at.to_s(:number)
      # Without updated_at - will append /id
      
      # This is usually called insode a cache() block
      #
      # @example Returns the cache key
      # @return [String] the string with or without updated_at
      def cache_key
        case
        when new_record?
          "#{self.class.model_name.cache_key}/new"
        when timestamp = self[:updated_at]
          timestamp = timestamp.utc.to_s(:number)
          "#{self.class.model_name.cache_key}/#{id}-#{timestamp}"
        else
          "#{self.class.model_name.cache_key}/#{id}"
        end
      end
      
    end
  end
end
