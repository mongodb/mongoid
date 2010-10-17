class Shelf
  include Mongoid::Document
  field :level, :type => Integer
  embedded_in :parent_shelf, :class_name => "Shelf", :cyclic => true
  embeds_one :child_shelf, :class_name => "Shelf", :cyclic => true
end
