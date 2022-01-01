# frozen_string_literal: true

class Alert
  include Mongoid::Document
  field :message, type: :string
  belongs_to :account
  has_many :items
  belongs_to :post
end
