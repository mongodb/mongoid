# frozen_string_literal: true
# encoding: utf-8

class Purchase
  include Mongoid::Document
  embeds_many :line_items
end
