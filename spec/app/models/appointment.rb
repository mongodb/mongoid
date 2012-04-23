class Appointment
  include Mongoid::Document
  field :active, type: Boolean, default: true
  field :timed, type: Boolean, default: true
  embedded_in :person
  default_scope where(active: true)
end
