class Sound
  include Mongoid::Document
  field :active, type: Boolean
  default_scope where(active: true)
end
