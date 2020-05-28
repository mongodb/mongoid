# frozen_string_literal: true
# encoding: utf-8

class Registry
  include Mongoid::Document
  field :data, type: BSON::Binary
end
