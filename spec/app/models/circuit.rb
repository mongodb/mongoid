# frozen_string_literal: true
# encoding: utf-8

class Circuit
  include Mongoid::Document
  embeds_many :buses, order: [[ :saturday, :asc], [ :departure_time, :asc], [ :number, :asc ]]
end
