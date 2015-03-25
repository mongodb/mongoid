class IdKey
  include Mongoid::Document
  field :key
  alias_method :id,  :key
  alias_method :id=, :key=
end
