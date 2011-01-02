class Agent
  include Mongoid::Document
  field :title
  field :number
  embeds_many :names, :as => :namable
end
