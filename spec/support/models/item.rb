# frozen_string_literal: true
# encoding: utf-8

class Item
  include Mongoid::Document
  field :title, type: String
  field :is_rss, type: Mongoid::Boolean, default: false
  field :user_login, type: String
end

require "support/models/sub_item"
