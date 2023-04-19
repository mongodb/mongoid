# frozen_string_literal: true
# rubocop:todo all

class Truck < Vehicle
  embeds_one :bed

  field :capacity, type: Integer
end
