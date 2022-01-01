# frozen_string_literal: true

class Item
  include Mongoid::Document
  field :title, type: :string
  field :is_rss, type: :boolean, default: false
  field :user_login, type: :string
end

require "support/models/sub_item"
