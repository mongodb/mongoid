# frozen_string_literal: true
# encoding: utf-8

class OrderedPost
  include Mongoid::Document
  field :title, type: String
  field :rating, type: Integer
  belongs_to :person

  after_destroy do
    person.title = 'Minus one ordered post.'
    person.save
  end
end
