class ConsumptionPeriod
  include Mongoid::Document

  belongs_to :account

  field :started_at, type: Time
end
