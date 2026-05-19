# frozen_string_literal: true

class NestedAuthor
  include Mongoid::Document

  field :name, type: String
  has_one :post, class_name: 'NestedPost'
  accepts_nested_attributes_for :post
end

class NestedComment
  include Mongoid::Document

  field :body, type: String
  belongs_to :post, class_name: 'NestedPost'
end

class NestedPost
  include Mongoid::Document

  field :title, type: String
  belongs_to :author, class_name: 'NestedAuthor'
  has_many :comments, class_name: 'NestedComment'
  accepts_nested_attributes_for :comments
end

class NestedBook
  include Mongoid::Document

  embeds_one :cover, class_name: 'NestedCover'
  embeds_many :pages, class_name: 'NestedPage'

  accepts_nested_attributes_for :cover, :pages
end

class NestedCover
  include Mongoid::Document

  field :title, type: String
  embedded_in :book, class_name: 'NestedBook'
end

class NestedPage
  include Mongoid::Document

  field :number, type: Integer
  embedded_in :book, class_name: 'NestedBook'
end

# Models for testing MONGOID-5911: no partial or premature writes via nested
# attributes on referenced associations.
class NestedValidatedParent
  include Mongoid::Document

  field :status, type: String
  has_many :labeled_items, class_name: 'NestedLabeledItem'
  accepts_nested_attributes_for :labeled_items
  validates :status, inclusion: { in: %w[active inactive] }
end

class NestedLabeledItem
  include Mongoid::Document

  field :label, type: String
  belongs_to :nested_validated_parent
end
