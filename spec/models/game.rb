class Game
  include Mongoid::Document
  field :high_score, :default => 500, :required => true
  field :score, :type => Integer, :default => 0
  belongs_to_related :person
  enslave and cache
end
