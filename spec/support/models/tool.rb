# frozen_string_literal: true
# encoding: utf-8

class Tool
  include Mongoid::Document
  embedded_in :palette
  accepts_nested_attributes_for :palette
end

require "support/models/eraser"
require "support/models/pencil"
