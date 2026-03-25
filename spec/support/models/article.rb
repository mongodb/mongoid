# frozen_string_literal: true

class Article
  include Mongoid::Document

  field :author_id, type: Integer
  field :public, type: Mongoid::Boolean
  field :title, type: String
  field :is_rss, type: Mongoid::Boolean, default: false
  field :user_login, type: String

  has_and_belongs_to_many :tags, validate: false
  has_and_belongs_to_many :preferences, inverse_of: nil, validate: false
end
