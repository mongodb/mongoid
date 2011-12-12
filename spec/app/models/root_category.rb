class RootCategory
  include Mongoid::Document
  embeds_many :categories
end
