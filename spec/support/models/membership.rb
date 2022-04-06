# frozen_string_literal: true

class Membership
  include Mongoid::Document
  field :name, type: String
  embedded_in :account
end
