# encoding: utf-8
module Mongoid #:nodoc:

  # This module handles the behaviour for setting up document created at and
  # updated at timestamps.
  module Timestamps
    extend ActiveSupport::Concern

    included do
      include CreatedTimestamp
      include UpdatedTimestamp
      
      class_attribute :record_timestamps
      self.record_timestamps = true
    end
  end
end
