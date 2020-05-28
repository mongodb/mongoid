# frozen_string_literal: true
# encoding: utf-8

class Slave
  include Mongoid::Document
  field :first_name
  field :last_name
  embeds_many :address_numbers
end
