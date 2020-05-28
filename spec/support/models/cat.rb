# frozen_string_literal: true
# encoding: utf-8

class Cat
  include Mongoid::Document

  field :name

  belongs_to :person, primary_key: :username

end
