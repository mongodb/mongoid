# frozen_string_literal: true
# encoding: utf-8

class Even
  include Mongoid::Document
  field :name

  belongs_to :parent, class_name: 'Odd', inverse_of: :evens
  has_many :odds, inverse_of: :parent, autosave: true
end
