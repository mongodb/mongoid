# frozen_string_literal: true
# encoding: utf-8

class ArrayField
  include Mongoid::Document

  field :af, type: Array
end
