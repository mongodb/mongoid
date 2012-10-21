class Door
  include Mongoid::Document

  has_one    :door_key
  embeds_one :door_knob
end