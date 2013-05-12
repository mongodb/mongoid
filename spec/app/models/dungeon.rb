class Dungeon
  include Mongoid::Document
  has_and_belongs_to_many :dragons
end
