# frozen_string_literal: true

class Passport
  include Mongoid::Document

  field :number, type: :string
  field :country, type: :string
  field :exp, as: :expiration_date, type: :date
  field :name, localize: true
  field :localized_translations, localize: true

  embedded_in :person, autobuild: true

  embeds_many :passport_pages
end

class PassportPage
  include Mongoid::Document

  field :num_stamps, type: :integer
  embedded_in :passport
end
