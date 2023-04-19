# frozen_string_literal: true
# rubocop:todo all

class ShipmentAddress < Address
  field :shipping_name, localize: true
end
