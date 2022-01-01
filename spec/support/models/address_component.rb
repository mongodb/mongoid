# frozen_string_literal: true

class AddressComponent
  include Mongoid::Document
  field :street, type: :string
  embedded_in :person
end
