# frozen_string_literal: true
# encoding: utf-8

class ShortQuiz
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  field :name, type: String
end
