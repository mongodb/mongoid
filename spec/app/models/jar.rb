# frozen_string_literal: true
# encoding: utf-8

class Jar
  include Mongoid::Document
  include Mongoid::Timestamps::Updated

  field :_id, type: Integer, overwrite: true
  has_many :cookies, class_name: "Cookie"
end
