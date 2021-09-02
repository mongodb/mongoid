# frozen_string_literal: true

class Passport
  include Mongoid::Document

  field :number, type: String
  field :country, type: String
  field :exp, as: :expiration_date, type: Date

  embedded_in :person, autobuild: true
end
