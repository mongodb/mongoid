# frozen_string_literal: true
# rubocop:todo all

class Train
  include Mongoid::Document
  field :name, type: String

  store_in client: 'train_client', database: 'train_database'
end
