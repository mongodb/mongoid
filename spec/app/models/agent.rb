class Agent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  field :title, type: String
  field :number, type: String
  field :dob, type: Time
  embeds_many :names, as: :namable
  belongs_to :game
  belongs_to :agency, touch: true, autobuild: true

  def destroy_agency
    self.agency.destroy if self.agency
  end

  has_and_belongs_to_many :accounts
end
