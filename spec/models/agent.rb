class Agent
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  field :title
  field :number
  embeds_many :names, :as => :namable
  referenced_in :game
end
