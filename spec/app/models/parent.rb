class Parent
  include Mongoid::Document
  embeds_many :sub_items
end
