# frozen_string_literal: true
# rubocop:todo all

class VetVisit
  include Mongoid::Document
  field :date, type: Date
  embedded_in :pet
end
