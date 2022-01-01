# frozen_string_literal: true

class Scribe
  include Mongoid::Document
  field :name, type: :string
  embedded_in :owner
end
