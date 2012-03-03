class Augmentation
  include Mongoid::Document

  field :name

  embedded_in :player, inverse_of: :augmentation

  after_build do
    self.name = "Infolink (#{player.frags})"
  end
end
