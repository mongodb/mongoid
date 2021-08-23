# frozen_string_literal: true

class Symptom
  include Mongoid::Document
  field :name, type: String
  embedded_in :person
  default_scope ->{ asc(:name) }
end
