# frozen_string_literal: true

class Building
  include Mongoid::Document

  embeds_one :building_address, validate: false
  embeds_many :contractors
end
