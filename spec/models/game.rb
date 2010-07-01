class Game
  include Mongoid::Document
  field :high_score, :type => Integer, :default => 500
  field :score, :type => Integer, :default => 0
  referenced_in :person
  enslave and cache

  attr_protected :_id
end
