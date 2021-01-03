# frozen_string_literal: true
# encoding: utf-8

class Customer
  include Mongoid::Document

  field :name

  embeds_one :home_address, class_name: 'CustomerAddress', as: :addressable, autobuild: true, cascade_callbacks: true
  embeds_one :work_address, class_name: 'CustomerAddress', as: :addressable, autobuild: true, cascade_callbacks: true
end

class CustomerAddress
  include Mongoid::Document

  field :street, type: String
  field :city, type: String
  field :state, type: String
  embedded_in :addressable, polymorphic: true
end
