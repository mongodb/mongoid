class Topping
  include Mongoid::Document
  field :name
  belongs_to :pizza
end