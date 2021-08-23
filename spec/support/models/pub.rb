# frozen_string_literal: true

class Pub
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :location, type: Array
  index location: "2dsphere"
end
