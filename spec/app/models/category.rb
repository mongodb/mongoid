class RootCategory
  include Mongoid::Document
  embeds_many :categories
end

class Category
  include Mongoid::Document
  embedded_in :root_category
  embedded_in :category
  embeds_many :categories

  field :name
end
