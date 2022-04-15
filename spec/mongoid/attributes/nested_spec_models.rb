# frozen_string_literal: true

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

class NestedPost
  include Mongoid::Document

  field :title, type: String
  belongs_to :author, class_name: "NestedAuthor"
  has_many :comments, class_name: "NestedComment"
  accepts_nested_attributes_for :comments
end
