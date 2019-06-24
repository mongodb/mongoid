# frozen_string_literal: true
# encoding: utf-8

class StoreAsDupTest4
  include Mongoid::Document
  embedded_in :store_as_dup_test3
  field :name
end
