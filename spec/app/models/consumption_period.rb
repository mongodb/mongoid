# frozen_string_literal: true
# encoding: utf-8

class ConsumptionPeriod
  include Mongoid::Document

  belongs_to :account

  field :started_at, type: Time
end
