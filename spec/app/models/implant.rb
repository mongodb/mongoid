class Implant
  include Mongoid::Document

  field :name
  field :impressions, type: Integer, default: 0

  embedded_in :player, inverse_of: :implants

  after_build do |doc|
    doc.name = "Cochlear Implant (#{player.frags})"
  end

  after_find do |doc|
    doc.impressions += 1
  end
end
