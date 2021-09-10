# frozen_string_literal: true

class Customer
  include Mongoid::Document

  field :name

  embeds_one :home_address, class_name: 'CustomerAddress', as: :addressable
  embeds_one :work_address, class_name: 'CustomerAddress', as: :addressable
end
