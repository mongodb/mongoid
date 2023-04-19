# frozen_string_literal: true
# rubocop:todo all

class StoreAsDupTest2
  include Mongoid::Document
  embedded_in :store_as_dup_test1
  field :name
end
