# frozen_string_literal: true

class Augmentation
  include Mongoid::Document

  field :name

  embedded_in :player, inverse_of: :augmentation

  after_build do
    self.name = "Infolink (#{player.frags})"
  end

  field :after_find_player
  field :after_initialize_player

  after_find do |doc|
    doc.after_find_player = player
  end

  after_initialize do |doc|
    doc.after_initialize_player = player
  end
end
