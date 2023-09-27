# frozen_string_literal: true
# rubocop:todo all

class NestedAuthor
  include Mongoid::Document

  field :name, type: String
  has_one :post, class_name: "NestedPost"
  accepts_nested_attributes_for :post
end

class NestedComment
  include Mongoid::Document

  field :body, type: String
  belongs_to :post, class_name: "NestedPost"
end

class NestedLike
  include Mongoid::Document

  belongs_to :post, class_name: "NestedPost"
end

class NestedPost
  include Mongoid::Document

  field :title, type: String
  belongs_to :author, class_name: "NestedAuthor"
  has_many :comments, class_name: "NestedComment"
  accepts_nested_attributes_for :comments
  has_many :likes, class_name: "NestedLike", autosave: false
  accepts_nested_attributes_for :likes, autosave: true
end

class NestedBook
  include Mongoid::Document

  embeds_one :cover, class_name: "NestedCover"
  embeds_many :pages, class_name: "NestedPage"

  accepts_nested_attributes_for :cover, :pages
end

class NestedCover
  include Mongoid::Document

  field :title, type: String
  embedded_in :book, class_name: "NestedBook"
end

class NestedPage
  include Mongoid::Document

  field :number, type: Integer
  embedded_in :book, class_name: "NestedBook"
end
