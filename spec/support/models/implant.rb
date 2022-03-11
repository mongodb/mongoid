# frozen_string_literal: true

class Implant
  include Mongoid::Document

  field :name
  field :impressions, type: Integer, default: 0

  embedded_in :player, inverse_of: :implants

  after_build do |doc|
    doc.name = "Cochlear Implant (#{player.frags})"
  end

  field :after_find_player

  after_find do |doc|
    doc.impressions += 1
    doc.after_find_player = player
  end

  after_initialize do |doc|
    doc.after_initialize_player = player
  end
end
