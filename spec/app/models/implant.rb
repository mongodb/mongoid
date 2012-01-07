class Implant
  include Mongoid::Document

  field :name

  embedded_in :player, :inverse_of => :implants

  after_build do
    self.name = "Cochlear Implant (#{player.frags})"
  end
end
