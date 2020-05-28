# frozen_string_literal: true
# encoding: utf-8

class LineItem
  include Mongoid::Document
  embedded_in :purchase
  belongs_to :product, polymorphic: true
  validates :product, presence: true, uniqueness: { scope: :product }
end
