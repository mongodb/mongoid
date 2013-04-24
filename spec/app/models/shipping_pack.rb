class ShippingPack < Pack
  belongs_to :subscription, counter_cache: true
end
