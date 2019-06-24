# frozen_string_literal: true
# encoding: utf-8

class Princess
  include Mongoid::Document
  field :primary_color
  field :name, type: String
  def color
    primary_color.to_s
  end
  validates_presence_of :color
  validates :name, presence: true, on: :update
end
