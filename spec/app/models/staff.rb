# frozen_string_literal: true
# encoding: utf-8

class Staff
  include Mongoid::Document

  embedded_in :company

  field :age, type: Integer
end
