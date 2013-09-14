class Recipe
  include Mongoid::Document
  belongs_to :drink
  field :drink_name, default: -> { drink.name }
end
