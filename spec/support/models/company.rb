# frozen_string_literal: true

class Company
  include Mongoid::Document

  embeds_many :staffs

  has_many :products
end
