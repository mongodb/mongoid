class Palette
  include Mongoid::Document
  embedded_in :canvas
  embeds_many :tools
end
