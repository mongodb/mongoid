# frozen_string_literal: true
# rubocop:todo all

class Circuit
  include Mongoid::Document
  embeds_many :buses, order: [[ :saturday, :asc], [ :departure_time, :asc], [ :number, :asc ]]
end
