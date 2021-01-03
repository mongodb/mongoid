# frozen_string_literal: true
# encoding: utf-8

class Customer
  include Mongoid::Document

  field :name

  embeds_one :home_address, class_name: 'Address', as: :addressable, autobuild: true
  embeds_one :work_address, class_name: 'Address', as: :addressable, autobuild: true
end
