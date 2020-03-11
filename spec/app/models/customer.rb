# frozen_string_literal: true
# encoding: utf-8

class Customer
  include Mongoid::Document

  embeds_one :address, as: :addressable

  delegate :name, to: :address
end
