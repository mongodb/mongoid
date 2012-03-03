class Shape
  include Mongoid::Document
  field :x, type: Integer, default: 0
  field :y, type: Integer, default: 0

  embedded_in :canvas

  def render; end
end

require "app/models/circle"
require "app/models/square"
