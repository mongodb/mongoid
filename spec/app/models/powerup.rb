class Powerup
  include Mongoid::Document

  field :name

  belongs_to :player, inverse_of: :powerup

  after_build do
    self.name = "Quad Damage (#{player.frags})"
  end
end
