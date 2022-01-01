# frozen_string_literal: true

class CustomerAddress
  include Mongoid::Document

  field :street, type: :string
  field :city, type: :string
  field :state, type: :string

  embedded_in :addressable, polymorphic: true
end
