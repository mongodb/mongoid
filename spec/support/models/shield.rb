# frozen_string_literal: true
class Shield
  include Mongoid::Document

  has_and_belongs_to_many :players

  field :after_find_player
  field :after_initialize_player
  field :after_default_player, default: ->{ players.first&._id }

  after_find do |doc|
    doc.after_find_player = players.first&._id
  end

  after_initialize do |doc|
    doc.after_initialize_player = players.first&._id
  end
end
