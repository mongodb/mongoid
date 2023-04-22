# frozen_string_literal: true
# rubocop:todo all

class ShippingPack < Pack
  belongs_to :subscription, counter_cache: true
end
