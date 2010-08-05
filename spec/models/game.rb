class Game
  include Mongoid::Document
  field :high_score, :type => Integer, :default => 500
  field :score, :type => Integer, :default => 0
  field :name
  referenced_in :person, :index => true
  enslave and cache

  attr_protected :_id

  set_callback(:initialize, :after) do |document|
    write_attribute("name", "Testing")
  end
end
