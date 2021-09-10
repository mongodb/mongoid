# frozen_string_literal: true

class Drug
  include Mongoid::Document
  field :name, type: String
  field :generic, type: Mongoid::Boolean
  belongs_to :person, counter_cache: true
end
