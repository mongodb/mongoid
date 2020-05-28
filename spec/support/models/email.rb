# frozen_string_literal: true
# encoding: utf-8

class Email
  include Mongoid::Document
  field :address
  validates_uniqueness_of :address
  embedded_in :patient
end
