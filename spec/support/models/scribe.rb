# frozen_string_literal: true

class Scribe
  include Mongoid::Document
  field :name, type: String
  embedded_in :owner
end
