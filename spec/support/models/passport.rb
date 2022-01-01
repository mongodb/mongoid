# frozen_string_literal: true

class Passport
  include Mongoid::Document

  field :number, type: :string
  field :country, type: :string
  field :exp, as: :expiration_date, type: :date

  embedded_in :person, autobuild: true
end
