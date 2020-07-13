# frozen_string_literal: true
# encoding: utf-8

class Instrument
    include Mongoid::Document
    field :owner, type: String, default: 0
end

require "support/models/guitar"
require "support/models/piano"