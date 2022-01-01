# frozen_string_literal: true

class WikiPage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: :string
  field :transient_property, type: :string
  field :author, type: :string
  field :description, type: :string, localize: true

  embeds_many :edits, validate: false
  # Must have dependent: :destroy
  has_many :comments, dependent: :destroy, validate: false
  has_many :child_pages, class_name: "WikiPage", dependent: :delete_all, inverse_of: :parent_pages
  belongs_to :parent_pages, class_name: "WikiPage", inverse_of: :child_pages
end
