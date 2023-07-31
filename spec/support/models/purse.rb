# frozen_string_literal: true
# rubocop:todo all

class Purse
  include Mongoid::Document

  field :brand, type: String

  embedded_in :person
end
