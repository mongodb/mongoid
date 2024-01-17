# frozen_string_literal: true
# rubocop:todo all

class ConsumptionPeriod
  include Mongoid::Document

  belongs_to :account

  field :started_at, type: Time
end
