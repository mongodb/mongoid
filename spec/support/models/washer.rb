# frozen_string_literal: true
# encoding: utf-8

class Washer
  include Mongoid::Document

  belongs_to :hole
end
