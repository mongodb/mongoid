# frozen_string_literal: true
# encoding: utf-8

class Pub
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :location, type: Array
  index location: "2dsphere"
end
