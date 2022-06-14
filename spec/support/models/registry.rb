# frozen_string_literal: true

class Registry
  include Mongoid::Document
  field :data, type: BSON::Binary
  field :obj_id, type: BSON::ObjectId
end
