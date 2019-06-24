# frozen_string_literal: true
# encoding: utf-8

class Updatable
  include Mongoid::Document

  field :updated_at, type: BSON::Timestamp
end
