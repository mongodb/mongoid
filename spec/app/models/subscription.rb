# frozen_string_literal: true
# encoding: utf-8

class Subscription
  include Mongoid::Document
  has_many :packs, class_name: "ShippingPack"
  field :packs_count, type: Integer
end
