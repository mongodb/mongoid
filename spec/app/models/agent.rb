class Agent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  field :title
  field :number
  embeds_many :names, :as => :namable
  belongs_to :game

  has_and_belongs_to_many :accounts
end
