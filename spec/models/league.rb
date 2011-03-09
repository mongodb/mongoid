class League
  include Mongoid::Document
  embeds_many :divisions
  accepts_nested_attributes_for :divisions, :allow_destroy => true
end
