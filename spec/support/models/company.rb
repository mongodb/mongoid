# frozen_string_literal: true
# encoding: utf-8

class Company
  include Mongoid::Document

  embeds_many :staffs
end
