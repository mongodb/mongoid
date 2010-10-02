class Rating
  include Mongoid::Document
  field :value, :type => Integer
  referenced_in :ratable, :polymorphic => true
end
