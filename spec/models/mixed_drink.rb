class MixedDrink
  include Mongoid::Document
  field :name

  belongs_to_related :liker, :class_name => 'Person'
end