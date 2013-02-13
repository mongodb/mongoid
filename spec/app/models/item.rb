class Item
  include Mongoid::Document
  field :title, type: String
  field :is_rss, type: Boolean, default: false
  field :user_login, type: String
end

require "app/models/sub_item"
