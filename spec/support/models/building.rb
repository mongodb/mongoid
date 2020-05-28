# frozen_string_literal: true
# encoding: utf-8

class Building
  include Mongoid::Document

  embeds_one :building_address, validate: false
  embeds_many :contractors
end
