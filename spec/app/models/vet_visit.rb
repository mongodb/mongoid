# frozen_string_literal: true

class VetVisit
  include Mongoid::Document
  field :date, type: Date
  embedded_in :pet
end
