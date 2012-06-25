class Pet
  include Mongoid::Document
  field :name
  field :weight, type: Float, default: 0.0
  field :destroy_flag, type: Boolean, default: false
  embeds_many :vet_visits
  embedded_in :pet_owner

  after_destroy :set_destroy_flag

  def set_destroy_flag
    self.destroy_flag = true
  end
end
