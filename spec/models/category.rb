class RootCategory
  include Mongoid::Document
  embeds_many :categories
end

class Category
  include Mongoid::Document
  embedded_in :root_category, :inverse_of => :categories
  embedded_in :category, :inverse_of => :categories
  embeds_many :categories

  field :name
end