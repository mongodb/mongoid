class Agent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  field :title, type: String
  field :number, type: String
  field :dob, type: Time
  embeds_many :names, as: :namable
  embeds_one :address
  belongs_to :game
  belongs_to :agency, touch: true, autobuild: true

  has_and_belongs_to_many :accounts
  has_and_belongs_to_many :basics
end
