# frozen_string_literal: true

class Circus
  include Mongoid::Document

  field :name

  embeds_many :animals
end
