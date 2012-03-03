class Topping
  include Mongoid::Document
  field :name, type: String
  belongs_to :pizza
end
