# frozen_string_literal: true

class Deed
  include Mongoid::Document
  field :title, type: String
  embedded_in :owner
end
