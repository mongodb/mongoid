# frozen_string_literal: true

class Symptom
  include Mongoid::Document
  field :name, type: :string
  embedded_in :person
  default_scope ->{ asc(:name) }
end
