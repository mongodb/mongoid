# frozen_string_literal: true

class Shop
  include Mongoid::Document
  field :title, type: String
  has_and_belongs_to_many :followers, inverse_of: :followed_shops, class_name: "User"
  belongs_to :user
end
