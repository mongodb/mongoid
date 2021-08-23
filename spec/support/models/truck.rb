# frozen_string_literal: true

class Truck < Vehicle
  embeds_one :bed

  field :capacity, type: Integer
end
