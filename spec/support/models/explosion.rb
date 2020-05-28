# frozen_string_literal: true
# encoding: utf-8

class Explosion
  include Mongoid::Document
  belongs_to :bomb
end
