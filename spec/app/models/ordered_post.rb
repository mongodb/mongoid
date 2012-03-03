class OrderedPost
  include Mongoid::Document
  field :title, type: String
  field :rating, type: Integer
  belongs_to :person
end
