class Appointment
  include Mongoid::Document
  field :active, type: Mongoid::Boolean, default: true
  field :timed, type: Mongoid::Boolean, default: true
  embedded_in :person
  default_scope ->{ where(active: true) }
end
