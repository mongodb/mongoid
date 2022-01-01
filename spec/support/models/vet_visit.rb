# frozen_string_literal: true

class VetVisit
  include Mongoid::Document
  field :date, type: :date
  embedded_in :pet
end
