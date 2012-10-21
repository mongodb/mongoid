class DoorKnob
  include Mongoid::Document

  embedded_in :door
end