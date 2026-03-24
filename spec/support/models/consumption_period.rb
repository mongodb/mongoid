# frozen_string_literal: true

class ConsumptionPeriod
  include Mongoid::Document

  belongs_to :account

  field :started_at, type: Time
end
