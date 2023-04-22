# frozen_string_literal: true
# rubocop:todo all

class Slave
  include Mongoid::Document
  field :first_name
  field :last_name
  embeds_many :address_numbers
end
