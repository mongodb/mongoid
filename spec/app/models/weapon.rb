# frozen_string_literal: true
# encoding: utf-8

class Weapon
  include Mongoid::Document

  field :name

  belongs_to :player, inverse_of: :weapons

  after_build do
    self.name = "Holy Hand Grenade (#{player.frags})"
  end
end
