# frozen_string_literal: true
# encoding: utf-8

class Truck < Vehicle
  embeds_one :bed

  field :capacity, type: Integer
end
