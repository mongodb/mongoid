class Palette
  include Mongoid::Document
  embedded_in :canvas
  embeds_many :tools
end

require "app/models/big_palette"
