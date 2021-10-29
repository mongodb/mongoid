# frozen_string_literal: true

class Bus
  include Mongoid::Document
  field :saturday, type: Mongoid::Boolean, default: false
  field :departure_time, type: Time
  field :number, type: Integer
  embedded_in :circuit
end
