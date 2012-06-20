class Registry
  include Mongoid::Document
  field :data, type: Moped::BSON::Binary
end
