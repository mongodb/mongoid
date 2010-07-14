class Agent
  include Mongoid::Document
  field :title
  field :number
  embeds_many :names
  references_many :posts, :foreign_key => :poster_id
end
