# frozen_string_literal: true
# encoding: utf-8

class StoreAsDupTest1
  include Mongoid::Document
  embeds_one :store_as_dup_test2, :store_as => :t
  field :name
end
