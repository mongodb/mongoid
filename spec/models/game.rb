class Game
  include Mongoid::Document
  field :high_score, :type => Integer, :default => 500
  field :score, :type => Integer, :default => 0
  field :name
  referenced_in :person, :index => true
  accepts_nested_attributes_for :person
  enslave and cache

  attr_protected :_id

  set_callback(:initialize, :after) do |document|
    write_attribute("name", "Testing") unless name
  end
end
