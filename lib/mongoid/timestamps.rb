# encoding: utf-8
require "mongoid/timestamps/timeless"
require "mongoid/timestamps/created"
require "mongoid/timestamps/updated"
require "mongoid/timestamps/short"

module Mongoid

  # This module handles the behaviour for setting up document created at and
  # updated at timestamps.
  module Timestamps
    extend ActiveSupport::Concern
    include Created
    include Updated
  end
end
