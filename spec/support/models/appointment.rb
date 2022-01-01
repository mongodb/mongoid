# frozen_string_literal: true

class Appointment
  include Mongoid::Document
  field :active, type: :boolean, default: true
  field :timed, type: :boolean, default: true
  embedded_in :person
  default_scope ->{ where(active: true) }
end
