# frozen_string_literal: true
# encoding: utf-8

class Answer
  include Mongoid::Document
  embedded_in :question

  field :position, type: Integer
end
