class Purchase
  include Mongoid::Document
  embeds_many :line_items
end
