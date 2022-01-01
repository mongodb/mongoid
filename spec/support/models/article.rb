# frozen_string_literal: true

class Article
  include Mongoid::Document

  field :author_id, type: :integer
  field :public, type: :boolean
  field :title, type: :string
  field :is_rss, type: :boolean, default: false
  field :user_login, type: :string

  has_and_belongs_to_many :tags, validate: false
  has_and_belongs_to_many :preferences, inverse_of: nil, validate: false
end
