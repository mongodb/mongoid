# frozen_string_literal: true

class Shape
  include Mongoid::Document
  field :x, type: Integer, default: 0
  field :y, type: Integer, default: 0

  embedded_in :canvas

  def render; end
end

require "support/models/circle"
require "support/models/square"
