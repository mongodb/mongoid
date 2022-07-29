# frozen_string_literal: true

class Circus
  include Mongoid::Document

  field :name
  field :slogan

  validates_uniqueness_of :slogan, allow_blank: true

  embeds_many :animals
end
