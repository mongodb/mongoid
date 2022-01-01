# frozen_string_literal: true

class Deed
  include Mongoid::Document
  field :title, type: :string
  embedded_in :owner
end
