class Item
  include Mongoid::Document
  field :title, type: String
  field :is_rss, type: Boolean, default: false
  field :user_login, type: String

  attr_protected :title, as: [:default, :parser]
  attr_protected :is_rss, as: :parser
  attr_protected :user_login
end

require "app/models/sub_item"
