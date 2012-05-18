class Registry
  include Mongoid::Document
  field :data, type: BSON::Binary
end
