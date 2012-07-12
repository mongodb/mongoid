class Pet
  include Mongoid::Document
  field :name
  field :weight, type: Float, default: 0.0
  embeds_many :vet_visits
  embedded_in :pet_owner

  after_destroy :set_destroy_flag
  attr_writer :destroy_flag

  def set_destroy_flag
    @destroy_flag = true
  end

  def destroy_flag
    @destroy_flag ||= false
  end
end
