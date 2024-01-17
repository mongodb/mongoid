# frozen_string_literal: true

class Purse
  include Mongoid::Document

  field :brand, type: String

  embedded_in :person
end
