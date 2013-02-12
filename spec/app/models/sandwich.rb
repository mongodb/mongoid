class Sandwich
  include Mongoid::Document
  has_and_belongs_to_many :meats
end
