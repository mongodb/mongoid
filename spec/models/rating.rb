class Rating
  include Mongoid::Document
  field :value, :type => Integer
  referenced_in :ratable, :polymorphic => true
  validates_numericality_of :value, :less_than => 100, :allow_nil => true
end
