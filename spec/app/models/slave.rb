# frozen_string_literal: true

class Slave
  include Mongoid::Document
  field :first_name
  field :last_name
  embeds_many :address_numbers
end
