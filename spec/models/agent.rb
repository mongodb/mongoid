class Agent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  field :title
  field :number
  embeds_many :names, :as => :namable
  referenced_in :game

  references_and_referenced_in_many :accounts
end
