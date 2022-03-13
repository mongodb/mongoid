# frozen_string_literal: true

class Powerup
  include Mongoid::Document

  field :name

  belongs_to :player, inverse_of: :powerup

  after_build do
    self.name = "Quad Damage (#{player.frags})"
  end

  field :after_find_player
  field :after_initialize_player
  field :after_default_player, default: ->{ self.player ? 1 : 2 }

  after_find do |doc|
    doc.after_find_player = player
  end

  after_initialize do |doc|
    doc.after_initialize_player = player
  end
end
