# frozen_string_literal: true
# encoding: utf-8

class Truck < Vehicle
  include Mongoid::Timestamps::Short

  embeds_one :bed
  embeds_many :crates, cascade_callbacks: true

  accepts_nested_attributes_for :crates

  field :capacity
end
