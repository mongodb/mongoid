# frozen_string_literal: true
# encoding: utf-8

class PostGenre
  include Mongoid::Document
  field :posts_count, type: Integer, default: 0

  has_many :posts, inverse_of: :genre
end
