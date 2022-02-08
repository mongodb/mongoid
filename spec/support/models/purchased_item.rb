# frozen_string_literal: true

class PurchasedItem
  include Mongoid::Document
  field :item_id, type: Mongoid::StringifiedSymbol

  validates_uniqueness_of :item_id

  embedded_in :order
end
