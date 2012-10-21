class DoorKey
  include Mongoid::Document

  belongs_to :door
end