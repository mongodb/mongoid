class Agent
  include Mongoid::Document
  field :number
  embeds_many :names
end
