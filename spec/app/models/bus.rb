class Bus
  include Mongoid::Document
  field :saturday, type: Boolean, default: false
  field :departure_time, type: Time
  field :number, type: Integer
  embedded_in :circuit
end
