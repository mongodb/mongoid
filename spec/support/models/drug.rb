# frozen_string_literal: true

class Drug
  include Mongoid::Document
  field :name, type: :string
  field :generic, type: :boolean
  belongs_to :person, counter_cache: true
end
