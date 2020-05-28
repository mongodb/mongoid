# frozen_string_literal: true
# encoding: utf-8

class StoreAsDupTest3
  include Mongoid::Document
  embeds_many :store_as_dup_test4s, :store_as => :t
  field :name
end
