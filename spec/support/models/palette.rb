# frozen_string_literal: true
# rubocop:todo all

class Palette
  include Mongoid::Document
  embedded_in :canvas
  embeds_many :tools
end

require "support/models/big_palette"
