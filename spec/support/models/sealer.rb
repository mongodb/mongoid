# frozen_string_literal: true
# encoding: utf-8

class Sealer
  include Mongoid::Document

  belongs_to :hole
end
