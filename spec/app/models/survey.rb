# frozen_string_literal: true

class Survey
  include Mongoid::Document
  embeds_many :questions
  accepts_nested_attributes_for :questions, reject_if: ->(a){ a[:content].blank? }, allow_destroy: true
end
