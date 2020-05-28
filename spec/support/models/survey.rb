# frozen_string_literal: true
# encoding: utf-8

class Survey
  include Mongoid::Document
  embeds_many :questions
  accepts_nested_attributes_for :questions, reject_if: ->(a){ a[:content].blank? }, allow_destroy: true
end
