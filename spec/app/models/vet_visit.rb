# frozen_string_literal: true
# encoding: utf-8

class VetVisit
  include Mongoid::Document
  field :date, type: Date
  embedded_in :pet
end
