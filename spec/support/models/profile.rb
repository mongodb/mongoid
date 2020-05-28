# frozen_string_literal: true
# encoding: utf-8

class Profile
  include Mongoid::Document
  field :name, type: String
  shard_key :name
end
