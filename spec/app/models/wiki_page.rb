# frozen_string_literal: true
# encoding: utf-8

class WikiPage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :transient_property, type: String
  field :author, type: String
  field :description, type: String, localize: true

  embeds_many :edits, validate: false
  has_many :comments, dependent: :destroy, validate: false
  has_many :child_pages, class_name: "WikiPage", dependent: :delete_all, inverse_of: :parent_pages
  belongs_to :parent_pages, class_name: "WikiPage", inverse_of: :child_pages
end
