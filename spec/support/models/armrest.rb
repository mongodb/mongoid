# frozen_string_literal: true
# encoding: utf-8

class Armrest
  include Mongoid::Document

  embedded_in :seat

  field :side
end
