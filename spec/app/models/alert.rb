# frozen_string_literal: true
# encoding: utf-8

class Alert
  include Mongoid::Document
  field :message, type: String
  belongs_to :account
  has_many :items
  belongs_to :post
end
