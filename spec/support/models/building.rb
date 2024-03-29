# frozen_string_literal: true
# rubocop:todo all

class Building
  include Mongoid::Document

  field :name, type: String

  embeds_one :building_address, validate: false
  embeds_many :contractors
end
